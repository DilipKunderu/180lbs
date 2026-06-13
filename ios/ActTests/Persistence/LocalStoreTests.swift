import GRDB
import XCTest
@testable import Act

/// `LocalStore` invariant + happy-path tests:
/// — PROFILE singleton, MEAL/DEVIATION mutex (incl. E1 symmetric reject),
///   SMOKE_CHECK / RELAPSE flow (incl. W7 happy path), WITHDRAWAL_STATE
///   (1...7) gate (incl. W7 happy path), HYDRATION + clean-streak cached
///   columns.
/// Bootstrap, infrastructure (DatabasePool/WAL, wall-clock hydration,
/// post-commit propagation), and DEVIATION_LOG.photo round-trip live in
/// sibling test files to keep each class body under 300 lines.
final class LocalStoreTests: XCTestCase {
    private var databaseQueue: DatabaseQueue!
    private var cloudMock: MockCKDatabase!
    private var cloudAdapter: MockCloudDatabaseAdapter!
    private var store: LocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        databaseQueue = try DatabaseQueue()
        cloudMock = MockCKDatabase()
        cloudAdapter = MockCloudDatabaseAdapter(database: cloudMock)
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

    // MARK: - PROFILE singleton

    func test_profileSingleton_rejectsSecondRowAttemptBeforeSave() throws {
        var profile = LocalStoreTestSupport.makeProfile()
        try store.upsertProfile(profile)

        profile.recordName = "another-profile-row"
        XCTAssertThrowsError(try store.upsertProfile(profile)) { error in
            XCTAssertEqual(error as? LocalStoreError, .profileMustUseSingletonID)
        }
    }

    // MARK: - SMOKE_CHECK / MEAL_LOG date-uniqueness

    func test_smokeCheckSameDate_upsertsInsteadOfDuplicateInsert() throws {
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "clean"))
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "relapse"))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM smoke_check")
            XCTAssertEqual(count, 1)

            let answer = try String.fetchOne(
                db,
                sql: "SELECT answer FROM smoke_check WHERE check_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(answer, "relapse")
        }
    }

    func test_mealLogSameDate_upsertsInsteadOfDuplicateInsert() throws {
        try store.upsertMealLog(LocalStoreTestSupport.makeMealLog(date: "2026-05-22", dishName: "Dish A"))
        try store.upsertMealLog(LocalStoreTestSupport.makeMealLog(date: "2026-05-22", dishName: "Dish B"))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM meal_log")
            XCTAssertEqual(count, 1)

            let dish = try String.fetchOne(
                db,
                sql: "SELECT dish_name FROM meal_log WHERE meal_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(dish, "Dish B")
        }
    }

    // MARK: - MEAL_LOG ⊕ DEVIATION_LOG mutex (symmetric)

    func test_deviationInsert_deletesExistingMealSameDateLocallyAndInCloud() throws {
        let meal = LocalStoreTestSupport.makeMealLog(date: "2026-05-22", dishName: "Meal Before Deviation")
        try store.upsertMealLog(meal)

        let deviation = LocalStoreTestSupport.makeDeviationLog(date: "2026-05-22")
        try store.upsertDeviationLog(deviation)

        try databaseQueue.read { db in
            let mealCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM meal_log WHERE meal_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(mealCount, 0)

            let deviationCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM deviation_log WHERE meal_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(deviationCount, 1)
        }

        XCTAssertTrue(cloudMock.allRecords(ofType: MealLogRow.recordType).isEmpty)
        XCTAssertEqual(cloudMock.allRecords(ofType: DeviationLogRow.recordType).count, 1)
    }

    /// E1: pairs with `test_deviationInsert_deletes…` so invariant 4 from
    /// `design.v3 §Data model` holds in both directions.
    func test_mealInsert_afterDeviationSameDate_throwsError() throws {
        try store.upsertDeviationLog(LocalStoreTestSupport.makeDeviationLog(date: "2026-05-22"))

        XCTAssertThrowsError(
            try store.upsertMealLog(LocalStoreTestSupport.makeMealLog(date: "2026-05-22", dishName: "Late dish"))
        ) { error in
            XCTAssertEqual(
                error as? LocalStoreError,
                .mealLogConflictsWithDeviation(mealDate: "2026-05-22")
            )
        }

        try databaseQueue.read { db in
            let mealCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM meal_log WHERE meal_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(mealCount, 0)

            let deviationCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM deviation_log WHERE meal_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(deviationCount, 1)
        }
    }

    // MARK: - RELAPSE_LOG gating + W7 happy path

    func test_relapseInsertWithoutRelapseSmokeCheck_throwsTypedError() throws {
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "clean"))

        XCTAssertThrowsError(
            try store.upsertRelapseLog(LocalStoreTestSupport.makeRelapseLog(date: "2026-05-22"))
        ) { error in
            XCTAssertEqual(error as? LocalStoreError, .relapseRequiresRelapseSmokeCheck)
        }
    }

    func test_upsertRelapseLog_withRelapseAnswerExisting_persistsRow() throws {
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "relapse"))
        try store.upsertRelapseLog(LocalStoreTestSupport.makeRelapseLog(date: "2026-05-22"))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM relapse_log")
            XCTAssertEqual(count, 1)

            let smokeCheckID = try String.fetchOne(db, sql: "SELECT smoke_check_id FROM relapse_log LIMIT 1")
            let parentSmokeCheckID = try String.fetchOne(
                db,
                sql: "SELECT id FROM smoke_check WHERE check_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(smokeCheckID, parentSmokeCheckID)
        }

        XCTAssertEqual(cloudMock.allRecords(ofType: RelapseLogRow.recordType).count, 1)
    }

    // MARK: - WITHDRAWAL_STATE day-1..7 gate + W7 happy path

    func test_withdrawalOutsideDayOneToSeven_isNoOp() throws {
        var profile = LocalStoreTestSupport.makeProfile()
        profile.quitDate = "2026-05-01"
        try store.upsertProfile(profile)

        try store.upsertWithdrawalState(LocalStoreTestSupport.makeWithdrawalState(date: "2026-05-22", day: 7))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM withdrawal_state")
            XCTAssertEqual(count, 0)
        }
    }

    func test_upsertWithdrawalState_withinDayOneToSeven_persistsRow() throws {
        // setUp's nowProvider == 2026-05-22T12:00Z; quit_date 2026-05-19 → day 3 (within [1,7]).
        var profile = LocalStoreTestSupport.makeProfile()
        profile.quitDate = "2026-05-19"
        try store.upsertProfile(profile)

        let withdrawal = LocalStoreTestSupport.makeWithdrawalState(date: "2026-05-22", day: 3)
        try store.upsertWithdrawalState(withdrawal)

        try databaseQueue.read { db in
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM withdrawal_state WHERE withdrawal_day = 3"
            )
            XCTAssertEqual(count, 1)

            let isWorstDay = try Bool.fetchOne(
                db,
                sql: "SELECT is_worst_day FROM withdrawal_state WHERE withdrawal_day = 3"
            )
            XCTAssertEqual(isWorstDay, true)
        }

        XCTAssertEqual(cloudMock.allRecords(ofType: WithdrawalStateRow.recordType).count, 1)
    }

    // MARK: - cached-column recomputation

    func test_profileCleanStreak_isRecomputedBeforeSave() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile())
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-20", answer: "clean"))
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-21", answer: "clean"))
        try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "clean"))

        try databaseQueue.read { db in
            let streak = try Int.fetchOne(db, sql: "SELECT clean_streak_days FROM profile LIMIT 1")
            XCTAssertEqual(streak, 3)
        }
    }

    func test_hydrationRunningTotal_isRecomputedBeforeSave() throws {
        try store.upsertHydrationLog(LocalStoreTestSupport.makeHydrationLog(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T10:00:00Z"),
            oz: 12
        ))
        try store.upsertHydrationLog(LocalStoreTestSupport.makeHydrationLog(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T11:00:00Z"),
            oz: 8
        ))

        try databaseQueue.read { db in
            let total = try Int.fetchOne(
                db,
                sql: "SELECT running_total_oz_cached FROM hydration_log ORDER BY logged_at DESC LIMIT 1"
            )
            XCTAssertEqual(total, 20)
        }
    }

    // MARK: - WEIGHT_LOG cache + cloud propagation

    /// G1 (design.v5 §Data model): after a WEIGHT_LOG upsert the PROFILE
    /// `current_weight_lb_cached` must equal the logged weight, not the
    /// original `start_weight_lb`. Uses start=310, log=305.2 so a bug that
    /// leaves the cache at start_weight_lb produces a meaningful failure.
    func test_upsertWeightLog_refreshesCurrentWeightCacheOnProfile() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile()) // start_weight_lb = 310

        let entry = WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T07:00:00Z"),
            weightLb: 305.2,
            source: "manual_pad",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(entry)

        let profile = try store.currentProfile()
        XCTAssertEqual(try XCTUnwrap(profile?.currentWeightLbCached), 305.2, accuracy: 0.001)
    }

    /// G1 edge-case: inserting an older-timestamped WEIGHT_LOG row after a
    /// more-recent one must NOT regress the cache to the older value. The cache
    /// must always reflect the entry with the maximum `logged_at`, not the
    /// last-inserted row.
    func test_upsertWeightLog_cacheReflectsLatestByLoggedAt_notInsertionOrder() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile()) // start_weight_lb = 310

        // Insert the NEWER weigh-in first.
        let newerEntry = WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T07:00:00Z"),
            weightLb: 303.0,
            source: "manual_pad",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(newerEntry)

        // Then insert an OLDER weigh-in with a higher weight.
        let olderEntry = WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-21T07:00:00Z"),
            weightLb: 307.5,
            source: "manual_pad",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(olderEntry)

        // Cache must stay at the NEWER entry's value (303.0), not regress to 307.5.
        let profile = try store.currentProfile()
        XCTAssertEqual(try XCTUnwrap(profile?.currentWeightLbCached), 303.0, accuracy: 0.001)
    }

    /// G1 cloud propagation: after `upsertWeightLog` a PROFILE CKRecord must
    /// appear in the cloud mock carrying the refreshed `current_weight_lb_cached`.
    func test_upsertWeightLog_propagatesRefreshedProfileCacheToCloud() throws {
        try store.upsertProfile(LocalStoreTestSupport.makeProfile()) // start_weight_lb = 310
        cloudMock.reset() // discard the initial profile save so we start clean

        let entry = WeightLogRow(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T07:00:00Z"),
            weightLb: 305.2,
            source: "manual_pad",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(entry)

        let profileRecords = cloudMock.allRecords(ofType: ProfileRow.recordType)
        XCTAssertEqual(profileRecords.count, 1, "PROFILE CKRecord must be saved to cloud after weight log")

        let propagatedWeight = profileRecords.first?["current_weight_lb_cached"] as? Double
        XCTAssertEqual(try XCTUnwrap(propagatedWeight), 305.2, accuracy: 0.001)

        // Verify the record uses the singleton record name.
        XCTAssertEqual(
            profileRecords.first?.recordID.recordName,
            ProfileRow.singletonRecordName
        )
    }
}
