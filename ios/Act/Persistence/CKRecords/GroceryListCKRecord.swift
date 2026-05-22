import CloudKit
import Foundation

extension GroceryListRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["shop_date"] = shopDate
        record["week_index"] = weekIndex
        record["items"] = itemsJSON
        record["sent_to_reminders"] = sentToReminders
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let shopDate = record.string(forKey: "shop_date"),
              let weekIndex = record.int(forKey: "week_index"),
              let itemsJSON = record.string(forKey: "items"),
              let sentToReminders = record.bool(forKey: "sent_to_reminders") else { return nil }
        self.init(id: id, shopDate: shopDate, weekIndex: weekIndex, itemsJSON: itemsJSON, sentToReminders: sentToReminders)
    }
}
