import Foundation
import GRDB

struct RotationRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "rotation"
    static let recordType = "ROTATION"

    var id: UUID
    var weekIndex: Int
    var slot: Int
    var dishName: String
    var prescribedKcal: Int
    var prescribedProteinG: Int
    var prescribedCarbsG: Int
    var prescribedFatG: Int
    var recipeURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case weekIndex = "week_index"
        case slot
        case dishName = "dish_name"
        case prescribedKcal = "prescribed_kcal"
        case prescribedProteinG = "prescribed_protein_g"
        case prescribedCarbsG = "prescribed_carbs_g"
        case prescribedFatG = "prescribed_fat_g"
        case recipeURL = "recipe_url"
    }
}
