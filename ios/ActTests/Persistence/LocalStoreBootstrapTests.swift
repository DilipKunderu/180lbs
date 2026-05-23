import GRDB
import XCTest
@testable import Act

/// E4: atomic bootstrap of the singleton PROFILE row + day-0 WITHDRAWAL_STATE
/// row. The architect resolved the design.v3 day-0 contradiction via Option C
/// (separate typed APIs); this suite covers the new `bootstrapProfile(_:)`
/// entry point and proves either both rows land or neither does.
final class LocalStoreBootstrapTests: XCTestCase {
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

    func test_bootstrapProfile_writesProfileAndDayZeroWithdrawalAtomically() throws {
        let draft = LocalStoreTestSupport.makeDraft(quitDate: "2026-05-22")
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
        let draft = LocalStoreTestSupport.makeDraft(quitDate: "2026-05-22")
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
            calendar: LocalStoreTestSupport.utcCalendar(),
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-22T12:00:00Z") },
            dayZeroWriter: { _, _ in throw injectedFailure }
        )

        XCTAssertThrowsError(
            try failingStore.bootstrapProfile(LocalStoreTestSupport.makeDraft(quitDate: "2026-05-22"))
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
}
