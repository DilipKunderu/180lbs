import Foundation
import GRDB

struct HydrationLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "hydration_log"
    static let recordType = "HYDRATION_LOG"

    var id: UUID
    var loggedAt: Date
    var oz: Int
    var source: String
    var runningTotalOzCached: Int

    enum CodingKeys: String, CodingKey {
        case id
        case loggedAt = "logged_at"
        case oz
        case source
        case runningTotalOzCached = "running_total_oz_cached"
    }
}
