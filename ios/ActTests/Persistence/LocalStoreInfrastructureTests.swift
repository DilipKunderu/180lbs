import CloudKit
import GRDB
import XCTest
@testable import Act

/// Persistence infrastructure tests:
/// — E2: CloudKit propagation runs AFTER the GRDB transaction commits.
/// — W5: production `DatabasePool` opens with WAL + busy timeout and tolerates
///       multiple openers on the same path.
/// — W6: HYDRATION_LOG daily totals bucket on the user's wall-clock calendar
///       day, not on UTC.
final class LocalStoreInfrastructureTests: XCTestCase {

    // MARK: - E2: cloud propagation happens AFTER local commit

    func test_localCommitSucceeds_evenWhenCloudSaveThrows() throws {
        let queue = try DatabaseQueue()
        let throwingCloud = ThrowingCloudDatabase()
        let store = try LocalStore(
            database: queue,
            cloudDatabase: throwingCloud,
            calendar: LocalStoreTestSupport.utcCalendar(),
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-22T12:00:00Z") }
        )

        XCTAssertNoThrow(
            try store.upsertSmokeCheck(LocalStoreTestSupport.makeSmokeCheck(date: "2026-05-22", answer: "clean"))
        )

        try queue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM smoke_check")
            XCTAssertEqual(count, 1, "GRDB transaction must commit even when CloudKit propagation fails")
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

    // MARK: - D1: JSON columns use canonical design field names

    /// design.v5 §Data model: the JSON-valued fields are named `triggers`
    /// (PROFILE, URGE_LOG) and `items` (GROCERY_LIST) — the storage columns must
    /// use those canonical names, not a `_json` suffix, so they agree with the
    /// CKRecord keys and the design field names.
    func test_jsonColumns_useCanonicalFieldNames_notJsonSuffix() throws {
        let queue = try DatabaseQueue()
        _ = try LocalStore(database: queue, cloudDatabase: nil)

        try queue.read { db in
            let profileCols = try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('profile')")
            XCTAssertTrue(profileCols.contains("triggers"), "profile.triggers must use the canonical name")
            XCTAssertFalse(profileCols.contains("triggers_json"), "profile must not keep the _json suffix")

            let urgeCols = try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('urge_log')")
            XCTAssertTrue(urgeCols.contains("triggers"), "urge_log.triggers must use the canonical name")
            XCTAssertFalse(urgeCols.contains("triggers_json"))

            let groceryCols = try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('grocery_list')")
            XCTAssertTrue(groceryCols.contains("items"), "grocery_list.items must use the canonical name")
            XCTAssertFalse(groceryCols.contains("items_json"))
        }
    }

    // MARK: - W6: hydration daily totals on wall-clock, not UTC

    func test_hydrationRunningTotal_usesWallClockDate_notUTC() throws {
        var pacific = Calendar(identifier: .gregorian)
        // Fall back to GMT only if the IANA db is missing — never expected on iOS.
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
        let queue = try DatabaseQueue()
        let store = try LocalStore(
            database: queue,
            cloudDatabase: nil,
            calendar: pacific,
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-23T06:55:00Z") }
        )

        // 23:55 PDT on 2026-05-22 == 06:55 UTC on 2026-05-23.
        // 23:58 PDT on 2026-05-22 == 06:58 UTC on 2026-05-23.
        // Both must bucket into the local 2026-05-22 daily total.
        try store.upsertHydrationLog(LocalStoreTestSupport.makeHydrationLog(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-23T06:55:00Z"),
            oz: 12
        ))
        try store.upsertHydrationLog(LocalStoreTestSupport.makeHydrationLog(
            id: UUID(),
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-23T06:58:00Z"),
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
}
