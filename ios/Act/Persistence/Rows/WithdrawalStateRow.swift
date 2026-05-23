import Foundation
import GRDB

struct WithdrawalStateRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "withdrawal_state"
    static let recordType = "WITHDRAWAL_STATE"

    var id: UUID
    var withdrawalDay: Int
    var asOfDate: String
    var currentHeroWord: String
    var isWorstDay: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case withdrawalDay = "withdrawal_day"
        case asOfDate = "as_of_date"
        case currentHeroWord = "current_hero_word"
        case isWorstDay = "is_worst_day"
    }
}
