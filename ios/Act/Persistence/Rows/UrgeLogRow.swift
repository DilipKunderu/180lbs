import Foundation
import GRDB

struct UrgeLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "urge_log"
    static let recordType = "URGE_LOG"

    var id: UUID
    var loggedAt: Date
    var intensity: Int
    var triggersJSON: String
    var didBreathing: Bool
    var breathingCyclesCompleted: Int

    enum CodingKeys: String, CodingKey {
        case id
        case loggedAt = "logged_at"
        case intensity
        case triggersJSON = "triggers_json"
        case didBreathing = "did_breathing"
        case breathingCyclesCompleted = "breathing_cycles_completed"
    }
}
