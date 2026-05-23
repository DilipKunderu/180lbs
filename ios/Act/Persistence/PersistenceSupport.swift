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
    case profileAlreadyBootstrapped
    case relapseRequiresRelapseSmokeCheck
    case mealLogConflictsWithDeviation(mealDate: String)
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

/// Input record for `LocalStore.bootstrapProfile(_:)`.
///
/// Mirrors `ProfileRow` field types for now; the next sub-task (#4) will land
/// the canonical `ProfileDraft` shape (Decimal, DateComponents) sketched in
/// `docs/architecture/onboarding-interface.md` and adapt this layer to it.
struct ProfileDraft: Equatable {
    var heightIn: Int
    var sex: String
    var age: Int
    var startWeightLb: Double
    var goalWeightLb: Double
    var wakeTime: String
    var mealWindowStart: String
    var mealWindowEnd: String
    var bedTime: String
    var kcalTarget: Int
    var proteinTargetG: Int
    var quitDate: String
    var whySentence: String
    var triggersJSON: String
}

/// Read-side projection returned by `LocalStore.bootstrapProfile(_:)`.
struct Profile: Equatable {
    let recordName: String
    let quitDate: String
    let startWeightLb: Double
    let goalWeightLb: Double
    let cleanStreakDays: Int
    let currentWeightLbCached: Double
    let adherencePctCached: Double

    init(from row: ProfileRow) {
        recordName = row.recordName
        quitDate = row.quitDate
        startWeightLb = row.startWeightLb
        goalWeightLb = row.goalWeightLb
        cleanStreakDays = row.cleanStreakDays
        currentWeightLbCached = row.currentWeightLbCached
        adherencePctCached = row.adherencePctCached
    }
}
