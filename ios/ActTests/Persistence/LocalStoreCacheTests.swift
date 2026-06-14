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

    // MARK: - single PROFILE CloudDelta per write (F1)

    /// upsertWeightLog calls both recomputeCurrentWeightCached and
    /// recomputeAdherencePct, each of which independently saves the profile row
    /// and returns a CloudDelta. Currently two PROFILE CKRecord saves are
    /// propagated per write (the first carries a stale snapshot). Desired: exactly
    /// one PROFILE save carrying all refreshed cached columns (design.v5 review,
    /// Finding 1). RED: current code propagates 2, not 1.
    func test_upsertWeightLog_propagatesExactlyOneProfileSave() throws {
        try bootstrapProfile(quitDate: "2026-05-01")
        cloudMock.reset() // clear the bootstrap save invocations

        try store.upsertWeightLog(weighIn("2026-05-22", 305.2))

        let profileSaves = cloudMock.savedRecordTypes.filter { $0 == ProfileRow.recordType }
        XCTAssertEqual(profileSaves.count, 1,
            "upsertWeightLog must propagate exactly ONE PROFILE CKRecord save; got \(profileSaves.count)")
    }

    /// upsertSmokeCheck calls both recomputeCleanStreakDays and
    /// recomputeAdherencePct, each of which independently saves the profile row.
    /// Same double-save hazard as upsertWeightLog.
    /// RED: current code propagates 2, not 1.
    func test_upsertSmokeCheck_propagatesExactlyOneProfileSave() throws {
        try bootstrapProfile(quitDate: "2026-05-01")
        cloudMock.reset() // clear the bootstrap save invocations

        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-21", answer: "clean"))

        let profileSaves = cloudMock.savedRecordTypes.filter { $0 == ProfileRow.recordType }
        XCTAssertEqual(profileSaves.count, 1,
            "upsertSmokeCheck must propagate exactly ONE PROFILE CKRecord save; got \(profileSaves.count)")
    }

    // MARK: - adherence rounds half away from zero (F2)

    /// Pins design.v5's "round half away from zero" rule at an exact .5 tie.
    /// 3 answered / 24 expected = 0.125 × 100 = 12.5 *exactly* in Double (1/8 and
    /// 100 are both exact), so the tie-break is observable: half-away-from-zero
    /// (Swift's `.rounded()` == `.toNearestOrAwayFromZero`) → 13; banker's
    /// rounding (`.toNearestOrEven`) → 12; truncation → 12. Asserting 13 locks
    /// the spec'd rule (design.v5 review, Finding 2).
    ///
    ///   now = 2026-05-22 Fri, quit 2026-05-01, window 2026-05-15..2026-05-21,
    ///   denominator 24. Seed weigh-ins on exactly 3 window days → answered 3.
    func test_adherence_roundsHalfAwayFromZero_atExactHalfTie() throws {
        try bootstrapProfile(quitDate: "2026-05-01")

        for day in ["2026-05-15", "2026-05-16", "2026-05-17"] {
            try store.upsertWeightLog(weighIn(day, 300)) // 3 answered / 24 → 12.5
        }

        XCTAssertEqual(
            try XCTUnwrap(try store.currentProfile()?.adherencePctCached),
            13,
            accuracy: 0.001,
            "12.5 must round half-away-from-zero to 13, not to 12 (banker's) or 12 (truncation)"
        )
    }

    // MARK: - adherence weight-log bucketing on wall-clock day (F3)

    /// Pins that the adherence weight-log day-boundary query uses the store's
    /// wall-clock calendar, not UTC. Mirrors the style of
    /// test_hydrationRunningTotal_usesWallClockDate_notUTC in
    /// LocalStoreInfrastructureTests. (design.v5 review, Finding 3.)
    ///
    /// Scenario:
    ///   Store calendar: America/Los_Angeles (UTC-7 in May, PDT).
    ///   now = 2026-05-23T06:55:00Z = 2026-05-22 23:55 PDT.
    ///     → local today = 2026-05-22 PDT → local window = [05-15…05-21] local.
    ///     → UTC today (buggy) = 2026-05-23 → UTC window (buggy) = [05-16…05-22].
    ///
    ///   The local window opens one day EARLIER than the UTC window: local 05-15
    ///   is inside the local 7-day window but OUTSIDE the UTC 7-day window.
    ///
    ///   Weigh-in at 2026-05-15T12:00:00Z (= 2026-05-15 05:00 PDT):
    ///     Local day: 2026-05-15 — offset 7 from local today → IN local window.
    ///     UTC day:   2026-05-15 — offset 8 from UTC today 2026-05-23
    ///                           → OUTSIDE the UTC 7-day window.
    ///
    ///   Only the weigh-in is seeded, no other events.
    ///   expected = 7×3 + 3 lift days = 24.
    ///   answered (local) = 1 → adherence = round(1/24×100) = round(4.17) = 4.
    ///   answered (UTC)   = 0 (weigh-in excluded) → adherence = 0.
    ///   Assert 4 to distinguish wall-clock from UTC bucketing.
    func test_adherence_weightLog_bucketsOnWallClockDay_notUTC() throws {
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
        let pacificQueue = try DatabaseQueue()
        let pacificStore = try LocalStore(
            database: pacificQueue,
            cloudDatabase: nil,
            calendar: pacific,
            // 2026-05-22 23:55 PDT = 2026-05-23 06:55 UTC.
            // Local today = 2026-05-22 PDT → local window [05-15…05-21].
            // UTC-buggy today = 2026-05-23 → UTC window [05-16…05-22]: 05-15 excluded.
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-23T06:55:00Z") }
        )

        // Bootstrap profile with quit date well before the window.
        var profile = LocalStoreTestSupport.makeProfile()
        profile.quitDate = "2026-05-01"
        try pacificStore.upsertProfile(profile)

        // 2026-05-15T12:00:00Z = 2026-05-15 05:00 PDT → local day 2026-05-15 (in local window,
        // offset 7 from 2026-05-22 PDT today). UTC day is 2026-05-15, which is offset 8 from
        // UTC-buggy today 2026-05-23 → falls outside the UTC window entirely.
        try pacificStore.upsertWeightLog(WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-15T12:00:00Z"),
            weightLb: 300,
            source: "manual_pad",
            isMorningWeighIn: false
        ))

        // Window: 7 days × 3 base events + 3 lift days (Mon/Wed/Fri in [05-15…05-21]:
        //   Fri 05-15, Mon 05-18, Wed 05-20) → expected=24.
        // Local bucketing: weigh-in on local 05-15 counted → answered=1 → round(1/24×100)=4.
        // UTC bucketing:   weigh-in on UTC 05-15 is offset 8 from UTC 05-23 → excluded → 0.
        XCTAssertEqual(
            try XCTUnwrap(try pacificStore.currentProfile()?.adherencePctCached),
            4,
            accuracy: 0.001,
            "weigh-in at 05:00 PDT on 05-15 is the 7th window day locally but outside the UTC window; must be counted"
        )
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
