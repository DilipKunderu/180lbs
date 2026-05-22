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
