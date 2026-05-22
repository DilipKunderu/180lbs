import CloudKit
import Foundation

extension HydrationLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["logged_at"] = loggedAt
        record["oz"] = oz
        record["source"] = source
        record["running_total_oz_cached"] = runningTotalOzCached
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let loggedAt = record.date(forKey: "logged_at"),
              let oz = record.int(forKey: "oz"),
              let source = record.string(forKey: "source"),
              let runningTotalOzCached = record.int(forKey: "running_total_oz_cached") else { return nil }
        self.init(id: id, loggedAt: loggedAt, oz: oz, source: source, runningTotalOzCached: runningTotalOzCached)
    }
}
