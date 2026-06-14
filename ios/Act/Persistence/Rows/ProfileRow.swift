import Foundation
import GRDB

struct ProfileRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "profile"
    static let singletonRecordName = "_profile_singleton"
    static let recordType = "PROFILE"

    var recordName: String
    var heightIn: Int
    var sex: String
    var age: Int
    var startWeightLb: Double
    var goalWeightLb: Double
    var wakeTime: String
    var mealWindowStart: String
    var mealWindowEnd: String
    var bedTime: String
    var kcalTarget: Int
    var proteinTargetG: Int
    var quitDate: String
    var whySentence: String
    var triggersJSON: String
    var cleanStreakDays: Int
    var currentWeightLbCached: Double
    var adherencePctCached: Double

    enum CodingKeys: String, CodingKey {
        case recordName = "record_name"
        case heightIn = "height_in"
        case sex
        case age
        case startWeightLb = "start_weight_lb"
        case goalWeightLb = "goal_weight_lb"
        case wakeTime = "wake_time"
        case mealWindowStart = "meal_window_start"
        case mealWindowEnd = "meal_window_end"
        case bedTime = "bed_time"
        case kcalTarget = "kcal_target"
        case proteinTargetG = "protein_target_g"
        case quitDate = "quit_date"
        case whySentence = "why_sentence"
        case triggersJSON = "triggers"
        case cleanStreakDays = "clean_streak_days"
        case currentWeightLbCached = "current_weight_lb_cached"
        case adherencePctCached = "adherence_pct_cached"
    }
}
