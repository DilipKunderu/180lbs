import Foundation
import GRDB

struct SmokeCheckRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "smoke_check"
    static let recordType = "SMOKE_CHECK"

    var id: UUID
    var checkDate: String
    var answeredAt: Date
    var answer: String

    enum CodingKeys: String, CodingKey {
        case id
        case checkDate = "check_date"
        case answeredAt = "answered_at"
        case answer
    }
}
