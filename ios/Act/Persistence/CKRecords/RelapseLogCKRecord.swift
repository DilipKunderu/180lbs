import CloudKit
import Foundation

extension RelapseLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["smoke_check_id"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: smokeCheckID.uuidString), action: .none)
        record["logged_at"] = loggedAt
        record["trigger"] = trigger
        record["where_text"] = whereText
        record["who_with_text"] = whoWithText
        record["how_much"] = howMuch
        record["how_much_unit"] = howMuchUnit
        record["stress_pre"] = stressPre
        record["craving_pre"] = cravingPre
        record["social_pressure_pre"] = socialPressurePre
        record["satisfaction_post"] = satisfactionPost
        record["regret_post"] = regretPost
        record["reflection_text"] = reflectionText
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let smokeCheckReference = record["smoke_check_id"] as? CKRecord.Reference,
              let smokeCheckID = UUID(uuidString: smokeCheckReference.recordID.recordName),
              let loggedAt = record.date(forKey: "logged_at"),
              let trigger = record.string(forKey: "trigger"),
              let whereText = record.string(forKey: "where_text"),
              let whoWithText = record.string(forKey: "who_with_text"),
              let howMuch = record.int(forKey: "how_much"),
              let howMuchUnit = record.string(forKey: "how_much_unit"),
              let stressPre = record.int(forKey: "stress_pre"),
              let cravingPre = record.int(forKey: "craving_pre"),
              let socialPressurePre = record.int(forKey: "social_pressure_pre"),
              let satisfactionPost = record.int(forKey: "satisfaction_post"),
              let regretPost = record.int(forKey: "regret_post"),
              let reflectionText = record.string(forKey: "reflection_text") else { return nil }
        self.init(
            id: id,
            smokeCheckID: smokeCheckID,
            loggedAt: loggedAt,
            trigger: trigger,
            whereText: whereText,
            whoWithText: whoWithText,
            howMuch: howMuch,
            howMuchUnit: howMuchUnit,
            stressPre: stressPre,
            cravingPre: cravingPre,
            socialPressurePre: socialPressurePre,
            satisfactionPost: satisfactionPost,
            regretPost: regretPost,
            reflectionText: reflectionText
        )
    }
}
