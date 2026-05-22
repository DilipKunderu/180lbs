import CloudKit
import Foundation

/// In-memory CKDatabase stand-in for tests that exercise the **CloudKit
/// save / fetch / delete sync path**.
///
/// ## Scope and boundary
/// `MockCKDatabase` is **only** the CloudKit-API surface shim. It is **NOT**
/// the harness for the v3 client-side persistence invariants:
///
///   - `PROFILE` singleton
///   - `SMOKE_CHECK.check_date` / `MEAL_LOG.meal_date` logical uniqueness
///   - `DEVIATION_LOG` vs `MEAL_LOG` mutual exclusion (deviation flow's
///     pre-delete)
///   - `RELAPSE_LOG` row exists only when `SMOKE_CHECK.answer = 'relapse'`
///   - `WITHDRAWAL_STATE` row exists iff `today − profile.quit_date ∈ [1, 7]`
///   - cached columns refreshed locally before save
///
/// Per `docs/design/design.v3.md` (lines 114, 160) these invariants are
/// enforced **client-side, against the local GRDB-backed SQLite mirror,
/// before any CloudKit save**. The schema todo (#5) introduces a separate
/// `LocalStoreTests` target backed by an in-memory GRDB `DatabaseQueue`
/// that owns those invariant tests. Do not conflate the two harnesses:
/// invariant violations must be caught **before** records reach this shim.
///
/// ## Storage
/// Records are keyed by full `CKRecord.ID` (recordName + zoneID), which
/// matches CloudKit's record identity: two records with the same recordName
/// in different zones are distinct.
///
/// ## Concurrency contract
/// Storage mutations and reads are serialised on a private queue.
/// Completion handlers fire on `DispatchQueue.global()` (matching real
/// `CKDatabase`, which delivers completions on an arbitrary background
/// queue) so callers may **safely re-enter** the database from inside a
/// completion — e.g. inspecting `allRecords(ofType:)` from a `save`
/// completion. Re-entering the storage queue from inside its own work
/// item would deadlock; firing the completion off-queue prevents that.
final class MockCKDatabase {

    private var store: [CKRecord.ID: CKRecord] = [:]
    private let queue = DispatchQueue(label: "com.act.coach.MockCKDatabase")

    // MARK: - CKDatabase surface (save / fetch / delete)

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            self.store[record.recordID] = record
            DispatchQueue.global().async {
                completionHandler(record, nil)
            }
        }
    }

    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        queue.async {
            let hit = self.store[recordID]
            DispatchQueue.global().async {
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
    }

    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        queue.async {
            let removed = self.store.removeValue(forKey: recordID) != nil
            DispatchQueue.global().async {
                if removed {
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
    }

    // MARK: - Test helpers

    /// Returns all stored records of the given recordType across all zones.
    ///
    /// Safe to call from inside a save / fetch / delete completion handler:
    /// the completion fires on `DispatchQueue.global()`, not on the storage
    /// queue, so this `queue.sync` does not deadlock.
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
