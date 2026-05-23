import CloudKit
import GRDB
import XCTest
@testable import Act

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
            calendar: Self.utcCalendar(),
            nowProvider: { Self.utcDate("2026-05-22T12:00:00Z") }
        )
    }

    override func tearDownWithError() throws {
        store = nil
        cloudAdapter = nil
        cloudMock = nil
        databaseQueue = nil
        try super.tearDownWithError()
    }

    // MARK: - existing invariants (carried forward)

    func test_profileSingleton_rejectsSecondRowAttemptBeforeSave() throws {
        var profile = Self.makeProfile()
        try store.upsertProfile(profile)

        profile.recordName = "another-profile-row"
        XCTAssertThrowsError(try store.upsertProfile(profile)) { error in
            XCTAssertEqual(error as? LocalStoreError, .profileMustUseSingletonID)
        }
    }

    func test_smokeCheckSameDate_upsertsInsteadOfDuplicateInsert() throws {
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "clean"))
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "relapse"))

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
        try store.upsertMealLog(Self.makeMealLog(date: "2026-05-22", dishName: "Dish A"))
        try store.upsertMealLog(Self.makeMealLog(date: "2026-05-22", dishName: "Dish B"))

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

    func test_deviationInsert_deletesExistingMealSameDateLocallyAndInCloud() throws {
        let meal = Self.makeMealLog(date: "2026-05-22", dishName: "Meal Before Deviation")
        try store.upsertMealLog(meal)

        let deviation = Self.makeDeviationLog(date: "2026-05-22")
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

    func test_relapseInsertWithoutRelapseSmokeCheck_throwsTypedError() throws {
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "clean"))

        XCTAssertThrowsError(try store.upsertRelapseLog(Self.makeRelapseLog(date: "2026-05-22"))) { error in
            XCTAssertEqual(error as? LocalStoreError, .relapseRequiresRelapseSmokeCheck)
        }
    }

    func test_withdrawalOutsideDayOneToSeven_isNoOp() throws {
        var profile = Self.makeProfile()
        profile.quitDate = "2026-05-01"
        try store.upsertProfile(profile)

        try store.upsertWithdrawalState(Self.makeWithdrawalState(date: "2026-05-22", day: 7))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM withdrawal_state")
            XCTAssertEqual(count, 0)
        }
    }

    func test_profileCleanStreak_isRecomputedBeforeSave() throws {
        try store.upsertProfile(Self.makeProfile())
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-20", answer: "clean"))
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-21", answer: "clean"))
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "clean"))

        try databaseQueue.read { db in
            let streak = try Int.fetchOne(db, sql: "SELECT clean_streak_days FROM profile LIMIT 1")
            XCTAssertEqual(streak, 3)
        }
    }

    func test_hydrationRunningTotal_isRecomputedBeforeSave() throws {
        try store.upsertHydrationLog(Self.makeHydrationLog(id: UUID(), loggedAt: Self.utcDate("2026-05-22T10:00:00Z"), oz: 12))
        try store.upsertHydrationLog(Self.makeHydrationLog(id: UUID(), loggedAt: Self.utcDate("2026-05-22T11:00:00Z"), oz: 8))

        try databaseQueue.read { db in
            let total = try Int.fetchOne(
                db,
                sql: "SELECT running_total_oz_cached FROM hydration_log ORDER BY logged_at DESC LIMIT 1"
            )
            XCTAssertEqual(total, 20)
        }
    }

    // MARK: - E1: symmetric MEAL_LOG ⊕ DEVIATION_LOG mutex

    func test_mealInsert_afterDeviationSameDate_throwsError() throws {
        try store.upsertDeviationLog(Self.makeDeviationLog(date: "2026-05-22"))

        XCTAssertThrowsError(
            try store.upsertMealLog(Self.makeMealLog(date: "2026-05-22", dishName: "Late dish"))
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

    // MARK: - E2: CloudKit calls happen AFTER GRDB commit

    func test_localCommitSucceeds_evenWhenCloudSaveThrows() throws {
        let queue = try DatabaseQueue()
        let throwingCloud = ThrowingCloudDatabase()
        let resilientStore = try LocalStore(
            database: queue,
            cloudDatabase: throwingCloud,
            calendar: Self.utcCalendar(),
            nowProvider: { Self.utcDate("2026-05-22T12:00:00Z") }
        )

        XCTAssertNoThrow(
            try resilientStore.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "clean"))
        )

        try queue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM smoke_check")
            XCTAssertEqual(count, 1, "GRDB transaction must commit even when CloudKit propagation fails")
        }
    }

    // MARK: - E3: DEVIATION_LOG.photo round-trips as CKAsset

    func test_deviationLog_photoRoundTripsAsCKAsset() throws {
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-deviation-\(UUID().uuidString).jpg")
        addTeardownBlock { try? FileManager.default.removeItem(at: tempPath) }
        FileManager.default.createFile(atPath: tempPath.path, contents: Data([0x00, 0x01]))

        let row = DeviationLogRow(
            id: UUID(),
            mealDate: "2026-05-22",
            loggedAt: Self.utcDate("2026-05-22T18:10:00Z"),
            reason: "social",
            photoURL: tempPath,
            kcalEst: 1800,
            proteinGEst: 90
        )

        let record = row.toCKRecord()
        XCTAssertNotNil(record["photo"] as? CKAsset, "DEVIATION_LOG.photo must encode as CKAsset")
        XCTAssertEqual((record["photo"] as? CKAsset)?.fileURL, tempPath)

        guard let recovered = DeviationLogRow(record: record) else {
            return XCTFail("CKRecord round-trip must succeed for DeviationLogRow")
        }
        XCTAssertEqual(recovered.photoURL, tempPath)
    }

    // MARK: - E4: atomic bootstrap API for PROFILE + day-0 WITHDRAWAL_STATE

    func test_bootstrapProfile_writesProfileAndDayZeroWithdrawalAtomically() throws {
        let draft = Self.makeDraft(quitDate: "2026-05-22")
        let profile = try store.bootstrapProfile(draft)

        XCTAssertEqual(profile.quitDate, "2026-05-22")
        XCTAssertEqual(profile.cleanStreakDays, 0)

        try databaseQueue.read { db in
            let profileRow = try ProfileRow.fetchOne(db)
            XCTAssertNotNil(profileRow)
            XCTAssertEqual(profileRow?.recordName, ProfileRow.singletonRecordName)
            XCTAssertEqual(profileRow?.quitDate, "2026-05-22")

            let withdrawalCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM withdrawal_state WHERE withdrawal_day = 0 AND as_of_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(withdrawalCount, 1)

            let heroWord = try String.fetchOne(
                db,
                sql: "SELECT current_hero_word FROM withdrawal_state WHERE withdrawal_day = 0"
            )
            XCTAssertEqual(heroWord, "Day 1")

            let isWorstDay = try Bool.fetchOne(
                db,
                sql: "SELECT is_worst_day FROM withdrawal_state WHERE withdrawal_day = 0"
            )
            XCTAssertEqual(isWorstDay, false)
        }

        XCTAssertEqual(cloudMock.allRecords(ofType: ProfileRow.recordType).count, 1)
        XCTAssertEqual(cloudMock.allRecords(ofType: WithdrawalStateRow.recordType).count, 1)
    }

    func test_bootstrapProfile_secondCallThrowsAlreadyBootstrapped() throws {
        let draft = Self.makeDraft(quitDate: "2026-05-22")
        _ = try store.bootstrapProfile(draft)

        XCTAssertThrowsError(try store.bootstrapProfile(draft)) { error in
            XCTAssertEqual(error as? LocalStoreError, .profileAlreadyBootstrapped)
        }
    }

    func test_bootstrapProfile_rollsBackBothRowsOnDayZeroFailure() throws {
        let queue = try DatabaseQueue()
        let injectedFailure = NSError(domain: "test.bootstrap-failure", code: 99)
        let failingStore = try LocalStore(
            database: queue,
            cloudDatabase: nil,
            calendar: Self.utcCalendar(),
            nowProvider: { Self.utcDate("2026-05-22T12:00:00Z") },
            dayZeroWriter: { _, _ in throw injectedFailure }
        )

        XCTAssertThrowsError(
            try failingStore.bootstrapProfile(Self.makeDraft(quitDate: "2026-05-22"))
        )

        try queue.read { db in
            XCTAssertEqual(
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM profile"), 0,
                "PROFILE row must be rolled back when day-0 WITHDRAWAL_STATE write fails"
            )
            XCTAssertEqual(
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM withdrawal_state"), 0,
                "no WITHDRAWAL_STATE row must remain after rollback"
            )
        }
    }

    // MARK: - W5: DatabasePool + WAL + busy timeout

    func test_databasePool_enablesWAL_andAllowsMultipleOpenersOnSamePath() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("act-wal-\(UUID().uuidString).sqlite").path
        addTeardownBlock {
            try? FileManager.default.removeItem(atPath: path)
            try? FileManager.default.removeItem(atPath: path + "-wal")
            try? FileManager.default.removeItem(atPath: path + "-shm")
        }

        let pool1 = try LocalStore.openProductionPool(atPath: path)
        let mode1 = try pool1.read { db in
            try String.fetchOne(db, sql: "PRAGMA journal_mode")
        }
        XCTAssertEqual(mode1?.lowercased(), "wal")

        let pool2 = try LocalStore.openProductionPool(atPath: path)
        let mode2 = try pool2.read { db in
            try String.fetchOne(db, sql: "PRAGMA journal_mode")
        }
        XCTAssertEqual(
            mode2?.lowercased(), "wal",
            "second pool opened on the same path must observe WAL and not deadlock"
        )
    }

    // MARK: - W6: hydration daily totals on wall-clock, not UTC

    func test_hydrationRunningTotal_usesWallClockDate_notUTC() throws {
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let queue = try DatabaseQueue()
        let pacificStore = try LocalStore(
            database: queue,
            cloudDatabase: nil,
            calendar: pacific,
            nowProvider: { Self.utcDate("2026-05-23T06:55:00Z") }
        )

        // 23:55 PDT on 2026-05-22 == 06:55 UTC on 2026-05-23.
        // 23:58 PDT on 2026-05-22 == 06:58 UTC on 2026-05-23.
        // Both must bucket into the local 2026-05-22 daily total.
        try pacificStore.upsertHydrationLog(Self.makeHydrationLog(
            id: UUID(),
            loggedAt: Self.utcDate("2026-05-23T06:55:00Z"),
            oz: 12
        ))
        try pacificStore.upsertHydrationLog(Self.makeHydrationLog(
            id: UUID(),
            loggedAt: Self.utcDate("2026-05-23T06:58:00Z"),
            oz: 8
        ))

        try queue.read { db in
            let total = try Int.fetchOne(
                db,
                sql: "SELECT running_total_oz_cached FROM hydration_log ORDER BY logged_at DESC LIMIT 1"
            )
            XCTAssertEqual(total, 20, "two sips on the same local calendar day must sum")
        }
    }

    // MARK: - W7: happy-path tests for upsertWithdrawalState + upsertRelapseLog

    func test_upsertWithdrawalState_withinDayOneToSeven_persistsRow() throws {
        // setUp's nowProvider == 2026-05-22; quit_date 2026-05-19 → today − quit == 3 (within [1,7]).
        var profile = Self.makeProfile()
        profile.quitDate = "2026-05-19"
        try store.upsertProfile(profile)

        let withdrawal = Self.makeWithdrawalState(date: "2026-05-22", day: 3)
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

    func test_upsertRelapseLog_withRelapseAnswerExisting_persistsRow() throws {
        try store.upsertSmokeCheck(Self.makeSmokeCheck(date: "2026-05-22", answer: "relapse"))
        try store.upsertRelapseLog(Self.makeRelapseLog(date: "2026-05-22"))

        try databaseQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM relapse_log")
            XCTAssertEqual(count, 1)

            let smokeCheckID = try String.fetchOne(
                db,
                sql: "SELECT smoke_check_id FROM relapse_log LIMIT 1"
            )
            let parentSmokeCheckID = try String.fetchOne(
                db,
                sql: "SELECT id FROM smoke_check WHERE check_date = ?",
                arguments: ["2026-05-22"]
            )
            XCTAssertEqual(smokeCheckID, parentSmokeCheckID)
        }

        XCTAssertEqual(cloudMock.allRecords(ofType: RelapseLogRow.recordType).count, 1)
    }

    // MARK: - factories

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func makeProfile() -> ProfileRow {
        ProfileRow(
            recordName: "_profile_singleton",
            heightIn: 72,
            sex: "M",
            age: 33,
            startWeightLb: 310,
            goalWeightLb: 180,
            wakeTime: "05:00",
            mealWindowStart: "18:00",
            mealWindowEnd: "19:00",
            bedTime: "21:30",
            kcalTarget: 2150,
            proteinTargetG: 190,
            quitDate: "2026-05-19",
            whySentence: "Family",
            triggersJSON: "[\"stress\"]",
            cleanStreakDays: 0,
            currentWeightLbCached: 310,
            adherencePctCached: 0
        )
    }

    private static func makeDraft(quitDate: String) -> ProfileDraft {
        ProfileDraft(
            heightIn: 72,
            sex: "M",
            age: 33,
            startWeightLb: 310,
            goalWeightLb: 180,
            wakeTime: "05:00",
            mealWindowStart: "18:00",
            mealWindowEnd: "19:00",
            bedTime: "21:30",
            kcalTarget: 2150,
            proteinTargetG: 190,
            quitDate: quitDate,
            whySentence: "Family",
            triggersJSON: "[\"stress\"]"
        )
    }

    private static func makeSmokeCheck(date: String, answer: String) -> SmokeCheckRow {
        SmokeCheckRow(
            id: UUID(),
            checkDate: date,
            answeredAt: utcDate("\(date)T21:00:00Z"),
            answer: answer
        )
    }

    private static func makeMealLog(date: String, dishName: String) -> MealLogRow {
        MealLogRow(
            id: UUID(),
            mealDate: date,
            loggedAt: utcDate("\(date)T18:10:00Z"),
            dishName: dishName,
            kcal: 2150,
            proteinG: 190,
            carbsG: 230,
            fatG: 60,
            includedShake: true
        )
    }

    private static func makeDeviationLog(date: String) -> DeviationLogRow {
        DeviationLogRow(
            id: UUID(),
            mealDate: date,
            loggedAt: utcDate("\(date)T18:10:00Z"),
            reason: "social",
            photoURL: nil,
            kcalEst: 2300,
            proteinGEst: 120
        )
    }

    private static func makeRelapseLog(date: String) -> RelapseLogRow {
        RelapseLogRow(
            id: UUID(),
            smokeCheckID: UUID(),
            loggedAt: utcDate("\(date)T21:05:00Z"),
            trigger: "stress",
            whereText: "Cafe",
            whoWithText: "alone",
            howMuch: 1,
            howMuchUnit: "bowls",
            stressPre: 8,
            cravingPre: 8,
            socialPressurePre: 1,
            satisfactionPost: 2,
            regretPost: 9,
            reflectionText: "Not worth it"
        )
    }

    private static func makeWithdrawalState(date: String, day: Int) -> WithdrawalStateRow {
        WithdrawalStateRow(
            id: UUID(),
            withdrawalDay: day,
            asOfDate: date,
            currentHeroWord: "Today",
            isWorstDay: day == 3
        )
    }

    private static func makeHydrationLog(id: UUID, loggedAt: Date, oz: Int) -> HydrationLogRow {
        HydrationLogRow(
            id: id,
            loggedAt: loggedAt,
            oz: oz,
            source: "manual_tap",
            runningTotalOzCached: 0
        )
    }

    private static func utcDate(_ text: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: text) else {
            fatalError("Invalid test date: \(text)")
        }
        return date
    }
}

private final class MockCloudDatabaseAdapter: CloudDatabase {
    private let database: MockCKDatabase

    init(database: MockCKDatabase) {
        self.database = database
    }

    func save(record: CKRecord) throws {
        if let error = try blocking({ completion in
            database.save(record) { _, error in
                completion(error)
            }
        }) {
            throw error
        }
    }

    func fetch(recordID: CKRecord.ID) throws -> CKRecord? {
        var fetched: CKRecord?
        let error = try blocking { completion in
            database.fetch(withRecordID: recordID) { record, fetchError in
                fetched = record
                completion(fetchError)
            }
        }
        if let nsError = error as NSError?,
           nsError.domain == CKErrorDomain,
           nsError.code == CKError.Code.unknownItem.rawValue {
            return nil
        }
        if let error {
            throw error
        }
        return fetched
    }

    func delete(recordID: CKRecord.ID) throws {
        let error = try blocking { completion in
            database.delete(withRecordID: recordID) { _, deleteError in
                completion(deleteError)
            }
        }
        if let nsError = error as NSError?,
           nsError.domain == CKErrorDomain,
           nsError.code == CKError.Code.unknownItem.rawValue {
            return
        }
        if let error {
            throw error
        }
    }

    private func blocking(_ body: (@escaping (Error?) -> Void) -> Void) throws -> Error? {
        let semaphore = DispatchSemaphore(value: 0)
        var capturedError: Error?
        body { error in
            capturedError = error
            semaphore.signal()
        }
        semaphore.wait()
        return capturedError
    }
}

/// Always-throwing CloudDatabase used to prove `LocalStore` still commits the
/// local SQLite write when CloudKit propagation fails (offline-first contract,
/// `design.v3 §Data model:160`).
private final class ThrowingCloudDatabase: CloudDatabase {
    func save(record: CKRecord) throws {
        throw NSError(domain: "test.cloud.save", code: 1)
    }

    func fetch(recordID: CKRecord.ID) throws -> CKRecord? { nil }

    func delete(recordID: CKRecord.ID) throws {
        throw NSError(domain: "test.cloud.delete", code: 2)
    }
}
