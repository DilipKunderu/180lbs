import CloudKit
import Foundation

extension DeviationLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["meal_date"] = mealDate
        record["logged_at"] = loggedAt
        record["reason"] = reason
        if let photoURL {
            record["photo"] = photoURL
        }
        record["kcal_est"] = kcalEst
        record["protein_g_est"] = proteinGEst
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let mealDate = record.string(forKey: "meal_date"),
              let loggedAt = record.date(forKey: "logged_at"),
              let reason = record.string(forKey: "reason"),
              let kcalEst = record.int(forKey: "kcal_est"),
              let proteinGEst = record.int(forKey: "protein_g_est") else { return nil }
        self.init(id: id, mealDate: mealDate, loggedAt: loggedAt, reason: reason, photoURL: record.string(forKey: "photo"), kcalEst: kcalEst, proteinGEst: proteinGEst)
    }
}
