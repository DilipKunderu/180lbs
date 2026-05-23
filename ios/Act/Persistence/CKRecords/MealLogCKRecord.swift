import CloudKit
import Foundation

extension MealLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["meal_date"] = mealDate
        record["logged_at"] = loggedAt
        record["dish_name"] = dishName
        record["kcal"] = kcal
        record["protein_g"] = proteinG
        record["carbs_g"] = carbsG
        record["fat_g"] = fatG
        record["included_shake"] = includedShake
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let mealDate = record.string(forKey: "meal_date"),
              let loggedAt = record.date(forKey: "logged_at"),
              let dishName = record.string(forKey: "dish_name"),
              let kcal = record.int(forKey: "kcal"),
              let proteinG = record.int(forKey: "protein_g"),
              let carbsG = record.int(forKey: "carbs_g"),
              let fatG = record.int(forKey: "fat_g"),
              let includedShake = record.bool(forKey: "included_shake") else { return nil }
        self.init(
            id: id,
            mealDate: mealDate,
            loggedAt: loggedAt,
            dishName: dishName,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            includedShake: includedShake
        )
    }
}
