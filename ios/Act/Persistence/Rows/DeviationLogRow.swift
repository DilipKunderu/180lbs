import Foundation
import GRDB

struct DeviationLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "deviation_log"
    static let recordType = "DEVIATION_LOG"

    var id: UUID
    var mealDate: String
    var loggedAt: Date
    var reason: String
    var photoURL: URL?
    var kcalEst: Int
    var proteinGEst: Int

    enum CodingKeys: String, CodingKey {
        case id
        case mealDate = "meal_date"
        case loggedAt = "logged_at"
        case reason
        case photoURL = "photo_url"
        case kcalEst = "kcal_est"
        case proteinGEst = "protein_g_est"
    }
}
