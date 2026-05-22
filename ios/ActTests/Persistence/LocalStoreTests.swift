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
            databaseQueue: databaseQueue,
            cloudDatabase: cloudAdapter,
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
