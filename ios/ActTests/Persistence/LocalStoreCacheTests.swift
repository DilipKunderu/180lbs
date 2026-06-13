import GRDB
import XCTest
@testable import Act

/// Cached-column recompute tests for `LocalStore` (design.v5 §Data model):
/// — `current_weight_lb_cached` refreshed on WEIGHT_LOG writes (G1).
/// — `adherence_pct_cached` 7-day-rolling formula refreshed on writes to the
///   five underlying tables (G2).
/// Split from `LocalStoreTests` to keep each class body under the SwiftLint
/// `type_body_length` limit and give the cache concern its own SRP home.
final class LocalStoreCacheTests: XCTestCase {
    private var databaseQueue: DatabaseQueue!
    private var cloudMock: MockCKDatabase!
    private var cloudAdapter: MockCloudDatabaseAdapter!
    private var store: LocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        databaseQueue = try DatabaseQueue()
        cloudMock = MockCKDatabase()
        cloudAdapter = MockCloudDatabaseAdapter(database: cloudMock)
        // Fixed clock: 2026-05-22 (Friday) 12:00Z. Adherence window is the 7
        // fully-elapsed days [2026-05-15 … 2026-05-21]; lift days in the
        // window are Fri 05-15, Mon 05-18, Wed 05-20 → denominator 7×3 + 3 = 24.
        store = try LocalStore(
            database: databaseQueue,
            cloudDatabase: cloudAdapter,
            calendar: LocalStoreTestSupport.utcCalendar(),
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-22T12:00:00Z") }
        )
    }

    override func tearDownWithError() throws {
        store = nil
        cloudAdapter = nil
        cloudMock = nil
        databaseQueue = nil
        try super.tearDownWithError()
    }

    // MARK: - current_weight_lb_cached (G1)

    /// After a WEIGHT_LOG upsert the PROFILE cache must equal the logged weight,
    /// not the original start_weight_lb (310 vs 305.2 makes the failure clear).
    func test_upsertWeightLog_refreshesCurrentWeightCacheOnProfile() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile()) // start 310
        try store.upsertWeightLog(weighIn("2026-05-22", 305.2))

        let profile = try store.currentProfile()
        XCTAssertEqual(try XCTUnwrap(profile?.currentWeightLbCached), 305.2, accuracy: 0.001)
    }

    /// Inserting an older-timestamped row after a newer one must NOT regress the
    /// cache: it tracks MAX(logged_at), not insertion order.
    func test_upsertWeightLog_cacheReflectsLatestByLoggedAt_notInsertionOrder() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile())
        try store.upsertWeightLog(weighIn("2026-05-22", 303.0)) // newer first
        try store.upsertWeightLog(weighIn("2026-05-21", 307.5)) // older second

        let profile = try store.currentProfile()
        XCTAssertEqual(try XCTUnwrap(profile?.currentWeightLbCached), 303.0, accuracy: 0.001)
    }

    /// A refreshed PROFILE CKRecord must reach the cloud after a weight log.
    func test_upsertWeightLog_propagatesRefreshedProfileCacheToCloud() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile())
        cloudMock.reset() // discard the initial profile save

        try store.upsertWeightLog(weighIn("2026-05-22", 305.2))

        let profiles = cloudMock.allRecords(ofType: ProfileRow.recordType)
        XCTAssertEqual(profiles.count, 1, "PROFILE CKRecord must be saved after weight log")
        XCTAssertEqual(try XCTUnwrap(profiles.first?["current_weight_lb_cached"] as? Double),
                       305.2, accuracy: 0.001)
        XCTAssertEqual(profiles.first?.recordID.recordName, ProfileRow.singletonRecordName)
    }

    // MARK: - adherence_pct_cached (G2)

    /// Every expected event answered across the window → 100%. One day uses a
    /// DEVIATION_LOG instead of a MEAL_LOG to pin "a logged deviation counts as
    /// an answered meal" (design.v5 §Cached projection).
    func test_adherence_fullyAnsweredWindow_is100() throws {
        try bootstrapProfile(quitDate: "2026-05-01")
        for day in windowDays {
            try store.upsertWeightLog(weighIn(day, 300))
            try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: day, answer: "clean"))
        }
        for day in windowDays where day != "2026-05-17" {
            try store.upsertMealLog(LocalStoreTestSupport.makeMealLog(date: day, dishName: "Dish"))
        }
        try store.upsertDeviationLog(LocalStoreTestSupport.makeDeviationLog(date: "2026-05-17"))
        for day in ["2026-05-15", "2026-05-18", "2026-05-20"] { // the 3 lift days
            try store.upsertLiftSession(completedLift(day))
        }

        XCTAssertEqual(try XCTUnwrap(try store.currentProfile()?.adherencePctCached), 100, accuracy: 0.001)
    }

    /// Weigh-ins only (7 of 24 expected) → round(7/24×100) = 29.
    func test_adherence_partialWeighInsOnly_roundsToNearest() throws {
        try bootstrapProfile(quitDate: "2026-05-01")
        for day in windowDays { try store.upsertWeightLog(weighIn(day, 300)) }

        XCTAssertEqual(try XCTUnwrap(try store.currentProfile()?.adherencePctCached), 29, accuracy: 0.001)
    }

    /// The current (partial) day is excluded from the window: an event logged
    /// today must not raise adherence, leaving an otherwise-empty window at 0%.
    func test_adherence_excludesCurrentDay_emptyWindowIsZero() throws {
        try bootstrapProfile(quitDate: "2026-05-01")
        try store.upsertWeightLog(weighIn("2026-05-22", 300)) // today only

        XCTAssertEqual(try XCTUnwrap(try store.currentProfile()?.adherencePctCached), 0, accuracy: 0.001)
    }

    /// When every window day predates quit_date there are no expected events
    /// (denominator 0) → 0%, never a misleading 100%.
    func test_adherence_zeroWhenWindowPredatesQuitDate() throws {
        try bootstrapProfile(quitDate: "2026-05-22") // quit today; window all before it
        try store.upsertWeightLog(weighIn("2026-05-22", 300))

        XCTAssertEqual(try XCTUnwrap(try store.currentProfile()?.adherencePctCached), 0, accuracy: 0.001)
    }

    // MARK: - helpers

    private let windowDays = [
        "2026-05-15", "2026-05-16", "2026-05-17",
        "2026-05-18", "2026-05-19", "2026-05-20", "2026-05-21"
    ]

    private func bootstrapProfile(quitDate: String) throws {
        var profile = LocalStoreTestSupport.makeProfile()
        profile.quitDate = quitDate
        try store.upsertProfile(profile)
    }

    private func weighIn(_ date: String, _ weight: Double) -> WeightLogRow {
        WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("\(date)T07:00:00Z"),
            weightLb: weight,
            source: "manual_pad",
            isMorningWeighIn: true
        )
    }

    private func completedLift(_ date: String) -> LiftSessionRow {
        LiftSessionRow(id: UUID(), sessionDate: date, dayLabel: "A", durationMin: 60, completed: true)
    }
}
