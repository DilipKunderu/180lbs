import CloudKit
import Foundation

/// In-memory CKDatabase stand-in for unit and persistence-invariant tests.
///
/// Stores CKRecords keyed by recordType → [recordName → CKRecord].
/// CloudKit is unreachable from CI runners; inject this wherever production
/// code accepts a database handle. Subsequent todos that introduce a schema
/// layer will extend this shim with the full set of record types and queries
/// they need.
///
/// Thread-safety: all mutations and reads are serialised on an internal queue.
final class MockCKDatabase {

    private var store: [String: [String: CKRecord]] = [:]
    private let queue = DispatchQueue(label: "com.act.coach.MockCKDatabase")

    // MARK: - CKDatabase surface (save / fetch / delete)

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            var bucket = self.store[record.recordType] ?? [:]
            bucket[record.recordID.recordName] = record
            self.store[record.recordType] = bucket
            completionHandler(record, nil)
        }
    }

    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            let hit = self.store.values
                .compactMap { $0[recordID.recordName] }
                .first { $0.recordID == recordID }
            if let hit {
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
            for (type, var bucket) in self.store where bucket[recordID.recordName] != nil {
                bucket.removeValue(forKey: recordID.recordName)
                self.store[type] = bucket
                completionHandler(recordID, nil)
                return
            }
            completionHandler(nil, NSError(
                domain: CKErrorDomain,
                code: CKError.Code.unknownItem.rawValue,
                userInfo: nil
            ))
        }
    }

    // MARK: - Test helpers

    /// Returns all stored records of the given recordType.
    func allRecords(ofType type: String) -> [CKRecord] {
        queue.sync {
            guard let bucket = store[type] else { return [] }
            return Array(bucket.values)
        }
    }

    /// Removes every record from the in-memory store.
    func reset() {
        queue.sync { store.removeAll() }
    }
}
