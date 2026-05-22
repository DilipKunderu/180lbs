import Foundation
import GRDB

struct GroceryListRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "grocery_list"
    static let recordType = "GROCERY_LIST"

    var id: UUID
    var shopDate: String
    var weekIndex: Int
    var itemsJSON: String
    var sentToReminders: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case shopDate = "shop_date"
        case weekIndex = "week_index"
        case itemsJSON = "items_json"
        case sentToReminders = "sent_to_reminders"
    }
}
