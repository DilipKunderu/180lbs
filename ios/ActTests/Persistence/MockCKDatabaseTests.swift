import CloudKit
import XCTest

/// Proves the MockCKDatabase harness works before any real schema exists.
///
/// These tests exercise the shim's save / fetch / delete surface and are the
/// canary tests for the persistence-invariant suite that subsequent todos will
/// extend. Each test covers exactly one observable behaviour.
final class MockCKDatabaseTests: XCTestCase {

    private var db: MockCKDatabase!

    override func setUp() {
        super.setUp()
        db = MockCKDatabase()
    }

    override func tearDown() {
        db.reset()
        db = nil
        super.tearDown()
    }

    // MARK: - save / fetch round-trip

    func test_fetch_returns_saved_record() {
        let recordID = CKRecord.ID(recordName: "smoke-001")
        let record = CKRecord(recordType: "SMOKE_CHECK", recordID: recordID)
        record["answer"] = "no"

        let didSave = expectation(description: "save completes")
        db.save(record) { _, error in
            XCTAssertNil(error, "save must succeed")
            didSave.fulfill()
        }
        wait(for: [didSave], timeout: 1)

        let didFetch = expectation(description: "fetch completes")
        db.fetch(withRecordID: recordID) { result, error in
            XCTAssertNil(error, "fetch must succeed for a saved record")
            XCTAssertEqual(
                result?["answer"] as? String, "no",
                "string field must survive a save→fetch round-trip"
            )
            didFetch.fulfill()
        }
        wait(for: [didFetch], timeout: 1)
    }

    // MARK: - delete

    func test_delete_removes_record_from_store() {
        let recordID = CKRecord.ID(recordName: "meal-001")
        let record = CKRecord(recordType: "MEAL_LOG", recordID: recordID)

        let didSave = expectation(description: "save completes")
        db.save(record) { _, _ in didSave.fulfill() }
        wait(for: [didSave], timeout: 1)

        let didDelete = expectation(description: "delete completes")
        db.delete(withRecordID: recordID) { _, error in
            XCTAssertNil(error, "delete must succeed for an existing record")
            didDelete.fulfill()
        }
        wait(for: [didDelete], timeout: 1)

        XCTAssertTrue(
            db.allRecords(ofType: "MEAL_LOG").isEmpty,
            "record must be absent from the store after delete"
        )
    }

    func test_fetch_after_delete_returns_error() {
        let recordID = CKRecord.ID(recordName: "meal-002")
        let record = CKRecord(recordType: "MEAL_LOG", recordID: recordID)

        let didSave = expectation(description: "save")
        db.save(record) { _, _ in didSave.fulfill() }
        wait(for: [didSave], timeout: 1)

        let didDelete = expectation(description: "delete")
        db.delete(withRecordID: recordID) { _, _ in didDelete.fulfill() }
        wait(for: [didDelete], timeout: 1)

        let didFetch = expectation(description: "fetch after delete")
        db.fetch(withRecordID: recordID) { result, error in
            XCTAssertNil(result, "deleted record must not be returned by fetch")
            XCTAssertNotNil(error, "fetch after delete must produce an error")
            didFetch.fulfill()
        }
        wait(for: [didFetch], timeout: 1)
    }

    // MARK: - zone isolation (record identity = recordName + zoneID)

    func test_save_distinguishes_records_with_same_recordName_in_different_zones() {
        let zoneA = CKRecordZone.ID(zoneName: "ZoneA", ownerName: CKCurrentUserDefaultName)
        let zoneB = CKRecordZone.ID(zoneName: "ZoneB", ownerName: CKCurrentUserDefaultName)
        let idA = CKRecord.ID(recordName: "shared-name", zoneID: zoneA)
        let idB = CKRecord.ID(recordName: "shared-name", zoneID: zoneB)
        let recordA = CKRecord(recordType: "MEAL_LOG", recordID: idA)
        recordA["zone"] = "A"
        let recordB = CKRecord(recordType: "MEAL_LOG", recordID: idB)
        recordB["zone"] = "B"

        let didSaveBoth = expectation(description: "both saved")
        didSaveBoth.expectedFulfillmentCount = 2
        db.save(recordA) { _, _ in didSaveBoth.fulfill() }
        db.save(recordB) { _, _ in didSaveBoth.fulfill() }
        wait(for: [didSaveBoth], timeout: 1)

        XCTAssertEqual(
            db.allRecords(ofType: "MEAL_LOG").count, 2,
            "records with the same recordName in different zones must coexist"
        )

        let didDelete = expectation(description: "delete zoneA")
        db.delete(withRecordID: idA) { _, error in
            XCTAssertNil(error, "delete must succeed for zoneA record")
            didDelete.fulfill()
        }
        wait(for: [didDelete], timeout: 1)

        let didFetchA = expectation(description: "fetch zoneA after delete")
        db.fetch(withRecordID: idA) { result, error in
            XCTAssertNil(result, "deleted record from zoneA must not return")
            XCTAssertNotNil(error, "fetch must error after delete")
            didFetchA.fulfill()
        }
        wait(for: [didFetchA], timeout: 1)

        let didFetchB = expectation(description: "fetch zoneB still present")
        db.fetch(withRecordID: idB) { result, error in
            XCTAssertNil(error, "fetch must succeed for zoneB record")
            XCTAssertEqual(
                result?["zone"] as? String, "B",
                "zoneB record must be untouched by zoneA delete"
            )
            didFetchB.fulfill()
        }
        wait(for: [didFetchB], timeout: 1)
    }

    // MARK: - re-entrant completion handler safety

    /// Regression test: calling `allRecords(ofType:)` (which uses `queue.sync`)
    /// from inside a `save` completion handler must NOT deadlock.
    ///
    /// Real `CKDatabase` invokes completion handlers on an arbitrary background
    /// queue rather than its internal serialization queue, and the schema
    /// todo's tests follow the same pattern (`db.save(record) { _, _ in
    /// XCTAssertEqual(db.allRecords(...).count, 1) }`). If the mock fires
    /// completions on its own storage queue, the inner `allRecords` call
    /// re-enters the queue under `sync`, which deadlocks until this test's
    /// expectation times out.
    func test_completion_handlers_can_reentrantly_inspect_state() {
        let recordID = CKRecord.ID(recordName: "reentrant-001")
        let record = CKRecord(recordType: "PROFILE", recordID: recordID)

        let didComplete = expectation(description: "save completion can call allRecords")
        db.save(record) { [weak db] _, error in
            XCTAssertNil(error, "save must succeed")
            XCTAssertEqual(
                db?.allRecords(ofType: "PROFILE").count, 1,
                "allRecords must be callable from inside save completion without deadlocking"
            )
            didComplete.fulfill()
        }
        wait(for: [didComplete], timeout: 1.0)
    }

    // MARK: - allRecords type isolation

    func test_allRecords_returns_only_the_requested_type() {
        let smokeID = CKRecord.ID(recordName: "smoke-002")
        let mealID = CKRecord.ID(recordName: "meal-003")
        let smoke = CKRecord(recordType: "SMOKE_CHECK", recordID: smokeID)
        let meal = CKRecord(recordType: "MEAL_LOG", recordID: mealID)

        let didSaveBoth = expectation(description: "both saved")
        didSaveBoth.expectedFulfillmentCount = 2
        db.save(smoke) { _, _ in didSaveBoth.fulfill() }
        db.save(meal) { _, _ in didSaveBoth.fulfill() }
        wait(for: [didSaveBoth], timeout: 1)

        XCTAssertEqual(db.allRecords(ofType: "SMOKE_CHECK").count, 1,
            "allRecords must return exactly one SMOKE_CHECK record")
        XCTAssertEqual(db.allRecords(ofType: "MEAL_LOG").count, 1,
            "allRecords must return exactly one MEAL_LOG record")
        XCTAssertEqual(db.allRecords(ofType: "DEVIATION_LOG").count, 0,
            "allRecords must return zero records for a type that was never saved")
    }
}
