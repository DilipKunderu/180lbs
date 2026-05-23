import CloudKit
import Foundation

extension WeightLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["logged_at"] = loggedAt
        record["weight_lb"] = weightLb
        record["source"] = source
        record["is_morning_weigh_in"] = isMorningWeighIn
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let loggedAt = record.date(forKey: "logged_at"),
              let weightLb = record.double(forKey: "weight_lb"),
              let source = record.string(forKey: "source"),
              let isMorningWeighIn = record.bool(forKey: "is_morning_weigh_in") else { return nil }
        self.init(id: id, loggedAt: loggedAt, weightLb: weightLb, source: source, isMorningWeighIn: isMorningWeighIn)
    }
}
