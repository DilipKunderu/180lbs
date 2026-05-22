import CloudKit
import Foundation

/// In-memory CKDatabase stand-in for unit and persistence-invariant tests.
///
/// Stores CKRecords keyed by full `CKRecord.ID` (recordName + zoneID), which
/// matches CloudKit's record identity: two records with the same recordName but
/// in different zones are distinct. CloudKit is unreachable from CI runners;
/// inject this wherever production code accepts a database handle. Subsequent
/// todos that introduce a schema layer will extend this shim with the full set
/// of record types and queries they need.
///
/// Thread-safety: all mutations and reads are serialised on an internal queue.
final class MockCKDatabase {

    private var store: [CKRecord.ID: CKRecord] = [:]
    private let queue = DispatchQueue(label: "com.act.coach.MockCKDatabase")

    // MARK: - CKDatabase surface (save / fetch / delete)

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            self.store[record.recordID] = record
            completionHandler(record, nil)
        }
    }

    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            if let hit = self.store[recordID] {
                completionHandler(hit, nil)
            } else {
                completionHandler(nil, NSError(
                    domain: CKErrorDomain,
                    code: CKError.Code.unknownItem.rawValue,
                    userInfo: nil
                ))
            }
        }
    }

    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        queue.async {
            if self.store.removeValue(forKey: recordID) != nil {
                completionHandler(recordID, nil)
            } else {
                completionHandler(nil, NSError(
                    domain: CKErrorDomain,
                    code: CKError.Code.unknownItem.rawValue,
                    userInfo: nil
                ))
            }
        }
    }

    // MARK: - Test helpers

    /// Returns all stored records of the given recordType across all zones.
    func allRecords(ofType type: String) -> [CKRecord] {
        queue.sync {
            store.values.filter { $0.recordType == type }
        }
    }

    /// Removes every record from the in-memory store.
    func reset() {
        queue.sync { store.removeAll() }
    }
}
