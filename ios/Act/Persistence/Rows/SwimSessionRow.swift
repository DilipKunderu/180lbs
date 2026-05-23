import Foundation
import GRDB

struct SwimSessionRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "swim_session"
    static let recordType = "SWIM_SESSION"

    var id: UUID
    var startedAt: Date
    var durationMin: Int
    var mode: String
    var hrAvgBpm: Int?
    var hrMaxBpm: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case durationMin = "duration_min"
        case mode
        case hrAvgBpm = "hr_avg_bpm"
        case hrMaxBpm = "hr_max_bpm"
    }
}
