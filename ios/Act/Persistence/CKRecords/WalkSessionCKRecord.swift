import CloudKit
import Foundation

extension WalkSessionRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["started_at"] = startedAt
        record["duration_min"] = durationMin
        record["steps"] = steps
        record["is_post_meal"] = isPostMeal
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let startedAt = record.date(forKey: "started_at"),
              let durationMin = record.int(forKey: "duration_min"),
              let steps = record.int(forKey: "steps"),
              let isPostMeal = record.bool(forKey: "is_post_meal") else { return nil }
        self.init(id: id, startedAt: startedAt, durationMin: durationMin, steps: steps, isPostMeal: isPostMeal)
    }
}
