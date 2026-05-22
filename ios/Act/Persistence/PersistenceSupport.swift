import CloudKit
import Foundation

protocol CloudDatabase {
    func save(record: CKRecord) throws
    func fetch(recordID: CKRecord.ID) throws -> CKRecord?
    func delete(recordID: CKRecord.ID) throws
}

enum LocalStoreError: Error, Equatable {
    case profileMustUseSingletonID
    case profileAlreadyExists
    case relapseRequiresRelapseSmokeCheck
}

enum PersistenceDate {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func calendarDateString(from date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalized = calendar.date(from: components) else {
            return "1970-01-01"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: normalized)
    }
}

extension CKRecord {
    func string(forKey key: String) -> String? { self[key] as? String }
    func int(forKey key: String) -> Int? { self[key] as? Int }
    func double(forKey key: String) -> Double? { self[key] as? Double }
    func bool(forKey key: String) -> Bool? { self[key] as? Bool }
    func date(forKey key: String) -> Date? { self[key] as? Date }
}
