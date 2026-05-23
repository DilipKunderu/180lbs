import CloudKit
import Foundation

extension LiftSessionRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["session_date"] = sessionDate
        record["day_label"] = dayLabel
        record["duration_min"] = durationMin
        record["completed"] = completed
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let sessionDate = record.string(forKey: "session_date"),
              let dayLabel = record.string(forKey: "day_label"),
              let durationMin = record.int(forKey: "duration_min"),
              let completed = record.bool(forKey: "completed") else { return nil }
        self.init(id: id, sessionDate: sessionDate, dayLabel: dayLabel, durationMin: durationMin, completed: completed)
    }
}
