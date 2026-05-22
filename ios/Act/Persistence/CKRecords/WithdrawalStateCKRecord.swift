import CloudKit
import Foundation

extension WithdrawalStateRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["withdrawal_day"] = withdrawalDay
        record["as_of_date"] = asOfDate
        record["current_hero_word"] = currentHeroWord
        record["is_worst_day"] = isWorstDay
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let withdrawalDay = record.int(forKey: "withdrawal_day"),
              let asOfDate = record.string(forKey: "as_of_date"),
              let currentHeroWord = record.string(forKey: "current_hero_word"),
              let isWorstDay = record.bool(forKey: "is_worst_day") else { return nil }
        self.init(id: id, withdrawalDay: withdrawalDay, asOfDate: asOfDate, currentHeroWord: currentHeroWord, isWorstDay: isWorstDay)
    }
}
