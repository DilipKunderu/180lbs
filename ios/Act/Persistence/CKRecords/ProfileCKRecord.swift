import CloudKit
import Foundation

extension ProfileRow {
    static func recordID(for recordName: String = singletonRecordName) -> CKRecord.ID {
        CKRecord.ID(recordName: recordName)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: recordName))
        record["height_in"] = heightIn
        record["sex"] = sex
        record["age"] = age
        record["start_weight_lb"] = startWeightLb
        record["goal_weight_lb"] = goalWeightLb
        record["wake_time"] = wakeTime
        record["meal_window_start"] = mealWindowStart
        record["meal_window_end"] = mealWindowEnd
        record["bed_time"] = bedTime
        record["kcal_target"] = kcalTarget
        record["protein_target_g"] = proteinTargetG
        record["quit_date"] = quitDate
        record["why_sentence"] = whySentence
        record["triggers"] = triggersJSON
        record["clean_streak_days"] = cleanStreakDays
        record["current_weight_lb_cached"] = currentWeightLbCached
        record["adherence_pct_cached"] = adherencePctCached
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let heightIn = record.int(forKey: "height_in"),
              let sex = record.string(forKey: "sex"),
              let age = record.int(forKey: "age"),
              let startWeightLb = record.double(forKey: "start_weight_lb"),
              let goalWeightLb = record.double(forKey: "goal_weight_lb"),
              let wakeTime = record.string(forKey: "wake_time"),
              let mealWindowStart = record.string(forKey: "meal_window_start"),
              let mealWindowEnd = record.string(forKey: "meal_window_end"),
              let bedTime = record.string(forKey: "bed_time"),
              let kcalTarget = record.int(forKey: "kcal_target"),
              let proteinTargetG = record.int(forKey: "protein_target_g"),
              let quitDate = record.string(forKey: "quit_date"),
              let whySentence = record.string(forKey: "why_sentence"),
              let triggersJSON = record.string(forKey: "triggers"),
              let cleanStreakDays = record.int(forKey: "clean_streak_days"),
              let currentWeightLbCached = record.double(forKey: "current_weight_lb_cached"),
              let adherencePctCached = record.double(forKey: "adherence_pct_cached") else {
            return nil
        }
        self.init(
            recordName: record.recordID.recordName,
            heightIn: heightIn,
            sex: sex,
            age: age,
            startWeightLb: startWeightLb,
            goalWeightLb: goalWeightLb,
            wakeTime: wakeTime,
            mealWindowStart: mealWindowStart,
            mealWindowEnd: mealWindowEnd,
            bedTime: bedTime,
            kcalTarget: kcalTarget,
            proteinTargetG: proteinTargetG,
            quitDate: quitDate,
            whySentence: whySentence,
            triggersJSON: triggersJSON,
            cleanStreakDays: cleanStreakDays,
            currentWeightLbCached: currentWeightLbCached,
            adherencePctCached: adherencePctCached
        )
    }
}
