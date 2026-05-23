import CloudKit
import Foundation

extension SmokeCheckRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["check_date"] = checkDate
        record["answered_at"] = answeredAt
        record["answer"] = answer
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let checkDate = record.string(forKey: "check_date"),
              let answeredAt = record.date(forKey: "answered_at"),
              let answer = record.string(forKey: "answer") else { return nil }
        self.init(id: id, checkDate: checkDate, answeredAt: answeredAt, answer: answer)
    }
}
