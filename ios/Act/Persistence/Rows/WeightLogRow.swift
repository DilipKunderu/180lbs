import Foundation
import GRDB

struct WeightLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "weight_log"
    static let recordType = "WEIGHT_LOG"

    var id: UUID
    var loggedAt: Date
    var weightLb: Double
    var source: String
    var isMorningWeighIn: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case loggedAt = "logged_at"
        case weightLb = "weight_lb"
        case source
        case isMorningWeighIn = "is_morning_weigh_in"
    }
}
