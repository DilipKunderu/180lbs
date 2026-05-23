import CloudKit
import Foundation
@testable import Act

/// Shared factories + cloud-adapter doubles for the `LocalStore` test suite.
/// Splitting these out of the XCTestCase subclasses keeps each test file's
/// type body under SwiftLint's `type_body_length` limit and gives the
/// individual concerns (invariants, bootstrap, infrastructure) clear SRP.
enum LocalStoreTestSupport {
    static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func utcDate(_ text: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: text) else {
            fatalError("Invalid test date: \(text)")
        }
        return date
    }

    static func makeProfile() -> ProfileRow {
        ProfileRow(
            recordName: "_profile_singleton",
            heightIn: 72,
            sex: "M",
            age: 33,
            startWeightLb: 310,
            goalWeightLb: 180,
            wakeTime: "05:00",
            mealWindowStart: "18:00",
            mealWindowEnd: "19:00",
            bedTime: "21:30",
            kcalTarget: 2150,
            proteinTargetG: 190,
            quitDate: "2026-05-19",
            whySentence: "Family",
            triggersJSON: "[\"stress\"]",
            cleanStreakDays: 0,
            currentWeightLbCached: 310,
            adherencePctCached: 0
        )
    }

    static func makeDraft(quitDate: String) -> ProfileDraft {
        ProfileDraft(
            heightIn: 72,
            sex: "M",
            age: 33,
            startWeightLb: 310,
            goalWeightLb: 180,
            wakeTime: "05:00",
            mealWindowStart: "18:00",
            mealWindowEnd: "19:00",
            bedTime: "21:30",
            kcalTarget: 2150,
            proteinTargetG: 190,
            quitDate: quitDate,
            whySentence: "Family",
            triggersJSON: "[\"stress\"]"
        )
    }

    static func makeSmokeCheck(date: String, answer: String) -> SmokeCheckRow {
        SmokeCheckRow(
            id: UUID(),
            checkDate: date,
            answeredAt: utcDate("\(date)T21:00:00Z"),
            answer: answer
        )
    }

    static func makeMealLog(date: String, dishName: String) -> MealLogRow {
        MealLogRow(
            id: UUID(),
            mealDate: date,
            loggedAt: utcDate("\(date)T18:10:00Z"),
            dishName: dishName,
            kcal: 2150,
            proteinG: 190,
            carbsG: 230,
            fatG: 60,
            includedShake: true
        )
    }

    static func makeDeviationLog(date: String) -> DeviationLogRow {
        DeviationLogRow(
            id: UUID(),
            mealDate: date,
            loggedAt: utcDate("\(date)T18:10:00Z"),
            reason: "social",
            photoURL: nil,
            kcalEst: 2300,
            proteinGEst: 120
        )
    }

    static func makeRelapseLog(date: String) -> RelapseLogRow {
        RelapseLogRow(
            id: UUID(),
            smokeCheckID: UUID(),
            loggedAt: utcDate("\(date)T21:05:00Z"),
            trigger: "stress",
            whereText: "Cafe",
            whoWithText: "alone",
            howMuch: 1,
            howMuchUnit: "bowls",
            stressPre: 8,
            cravingPre: 8,
            socialPressurePre: 1,
            satisfactionPost: 2,
            regretPost: 9,
            reflectionText: "Not worth it"
        )
    }

    static func makeWithdrawalState(date: String, day: Int) -> WithdrawalStateRow {
        WithdrawalStateRow(
            id: UUID(),
            withdrawalDay: day,
            asOfDate: date,
            currentHeroWord: "Today",
            isWorstDay: day == 3
        )
    }

    static func makeHydrationLog(id: UUID, loggedAt: Date, oz: Int) -> HydrationLogRow {
        HydrationLogRow(
            id: id,
            loggedAt: loggedAt,
            oz: oz,
            source: "manual_tap",
            runningTotalOzCached: 0
        )
    }
}

/// Bridge from the synchronous `CloudDatabase` protocol surface used by
/// `LocalStore` to the asynchronous `MockCKDatabase` harness. Kept here so
/// every test file in the suite can construct one without duplicating the
/// `DispatchSemaphore`-based blocking helper.
final class MockCloudDatabaseAdapter: CloudDatabase {
    private let database: MockCKDatabase

    init(database: MockCKDatabase) {
        self.database = database
    }

    func save(record: CKRecord) throws {
        if let error = try blocking({ completion in
            database.save(record) { _, error in
                completion(error)
            }
        }) {
            throw error
        }
    }

    func fetch(recordID: CKRecord.ID) throws -> CKRecord? {
        var fetched: CKRecord?
        let error = try blocking { completion in
            database.fetch(withRecordID: recordID) { record, fetchError in
                fetched = record
                completion(fetchError)
            }
        }
        if let nsError = error as NSError?,
           nsError.domain == CKErrorDomain,
           nsError.code == CKError.Code.unknownItem.rawValue {
            return nil
        }
        if let error {
            throw error
        }
        return fetched
    }

    func delete(recordID: CKRecord.ID) throws {
        let error = try blocking { completion in
            database.delete(withRecordID: recordID) { _, deleteError in
                completion(deleteError)
            }
        }
        if let nsError = error as NSError?,
           nsError.domain == CKErrorDomain,
           nsError.code == CKError.Code.unknownItem.rawValue {
            return
        }
        if let error {
            throw error
        }
    }

    private func blocking(_ body: (@escaping (Error?) -> Void) -> Void) throws -> Error? {
        let semaphore = DispatchSemaphore(value: 0)
        var capturedError: Error?
        body { error in
            capturedError = error
            semaphore.signal()
        }
        semaphore.wait()
        return capturedError
    }
}

/// Always-throwing CloudDatabase used to prove `LocalStore` still commits the
/// local SQLite write when CloudKit propagation fails (offline-first contract,
/// `design.v3 §Data model:160`).
final class ThrowingCloudDatabase: CloudDatabase {
    func save(record: CKRecord) throws {
        throw NSError(domain: "test.cloud.save", code: 1)
    }

    func fetch(recordID: CKRecord.ID) throws -> CKRecord? { nil }

    func delete(recordID: CKRecord.ID) throws {
        throw NSError(domain: "test.cloud.delete", code: 2)
    }
}
