import Foundation
import GRDB

struct LiftLogRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "lift_log"
    static let recordType = "LIFT_LOG"

    var id: UUID
    var liftSessionID: UUID
    var exercise: String
    var setNumber: Int
    var weightLb: Double
    var reps: Int
    var restSec: Int

    enum CodingKeys: String, CodingKey {
        case id
        case liftSessionID = "lift_session_id"
        case exercise
        case setNumber = "set_number"
        case weightLb = "weight_lb"
        case reps
        case restSec = "rest_sec"
    }
}
