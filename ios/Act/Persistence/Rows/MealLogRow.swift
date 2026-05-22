import Foundation
import GRDB

struct MealLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "meal_log"
    static let recordType = "MEAL_LOG"

    var id: UUID
    var mealDate: String
    var loggedAt: Date
    var dishName: String
    var kcal: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var includedShake: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case mealDate = "meal_date"
        case loggedAt = "logged_at"
        case dishName = "dish_name"
        case kcal
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case includedShake = "included_shake"
    }
}
