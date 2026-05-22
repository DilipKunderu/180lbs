import Foundation
import GRDB

struct WalkSessionRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "walk_session"
    static let recordType = "WALK_SESSION"

    var id: UUID
    var startedAt: Date
    var durationMin: Int
    var steps: Int
    var isPostMeal: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case durationMin = "duration_min"
        case steps
        case isPostMeal = "is_post_meal"
    }
}
