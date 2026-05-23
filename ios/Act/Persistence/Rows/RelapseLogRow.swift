import Foundation
import GRDB

struct RelapseLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "relapse_log"
    static let recordType = "RELAPSE_LOG"

    var id: UUID
    var smokeCheckID: UUID
    var loggedAt: Date
    var trigger: String
    var whereText: String
    var whoWithText: String
    var howMuch: Int
    var howMuchUnit: String
    var stressPre: Int
    var cravingPre: Int
    var socialPressurePre: Int
    var satisfactionPost: Int
    var regretPost: Int
    var reflectionText: String

    enum CodingKeys: String, CodingKey {
        case id
        case smokeCheckID = "smoke_check_id"
        case loggedAt = "logged_at"
        case trigger
        case whereText = "where_text"
        case whoWithText = "who_with_text"
        case howMuch = "how_much"
        case howMuchUnit = "how_much_unit"
        case stressPre = "stress_pre"
        case cravingPre = "craving_pre"
        case socialPressurePre = "social_pressure_pre"
        case satisfactionPost = "satisfaction_post"
        case regretPost = "regret_post"
        case reflectionText = "reflection_text"
    }
}
