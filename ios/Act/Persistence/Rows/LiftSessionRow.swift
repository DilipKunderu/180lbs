import Foundation
import GRDB

struct LiftSessionRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "lift_session"
    static let recordType = "LIFT_SESSION"

    var id: UUID
    var sessionDate: String
    var dayLabel: String
    var durationMin: Int
    var completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionDate = "session_date"
        case dayLabel = "day_label"
        case durationMin = "duration_min"
        case completed
    }
}
