import CloudKit
import Foundation

extension RotationRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["week_index"] = weekIndex
        record["slot"] = slot
        record["dish_name"] = dishName
        record["prescribed_kcal"] = prescribedKcal
        record["prescribed_protein_g"] = prescribedProteinG
        record["prescribed_carbs_g"] = prescribedCarbsG
        record["prescribed_fat_g"] = prescribedFatG
        if let recipeURL {
            record["recipe_url"] = recipeURL
        }
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let weekIndex = record.int(forKey: "week_index"),
              let slot = record.int(forKey: "slot"),
              let dishName = record.string(forKey: "dish_name"),
              let prescribedKcal = record.int(forKey: "prescribed_kcal"),
              let prescribedProteinG = record.int(forKey: "prescribed_protein_g"),
              let prescribedCarbsG = record.int(forKey: "prescribed_carbs_g"),
              let prescribedFatG = record.int(forKey: "prescribed_fat_g") else { return nil }
        self.init(
            id: id,
            weekIndex: weekIndex,
            slot: slot,
            dishName: dishName,
            prescribedKcal: prescribedKcal,
            prescribedProteinG: prescribedProteinG,
            prescribedCarbsG: prescribedCarbsG,
            prescribedFatG: prescribedFatG,
            recipeURL: record.string(forKey: "recipe_url")
        )
    }
}
