import CloudKit
import Foundation
import GRDB

/// Captures a CloudKit operation that must be propagated *after* the GRDB
/// transaction commits. Holding cloud calls inside the write block breaks the
/// offline-first contract (`design.v3 §Data model:160`) and risks deadlock
/// when a real CloudKit adapter re-enters `LocalStore` on its callback thread.
enum CloudDelta {
    case save(CKRecord)
    case delete(CKRecord.ID)
}

typealias DayZeroWriter = (Database, ProfileDraft) throws -> WithdrawalStateRow

final class LocalStore {
    /// Internal so the migrations extension in `LocalStoreMigrations.swift`
    /// can hand it to `DatabaseMigrator.migrate(_:)`. Treat as read-only —
    /// public callers should never reach in directly.
    let databaseWriter: any DatabaseWriter
    private let cloudDatabase: CloudDatabase?
    private let calendar: Calendar
    private let nowProvider: () -> Date
    private let dayZeroWriter: DayZeroWriter

    init(cloudDatabase: CloudDatabase? = nil) throws {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.act.coach")?
            .appendingPathComponent("act.sqlite") else {
            throw CocoaError(.fileNoSuchFile)
        }
        self.databaseWriter = try LocalStore.openProductionPool(atPath: url.path)
        self.cloudDatabase = cloudDatabase
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        self.calendar = calendar
        self.nowProvider = Date.init
        self.dayZeroWriter = LocalStore.defaultDayZeroWriter
        try migrateIfNeeded()
    }

    init(
        database: any DatabaseWriter,
        cloudDatabase: CloudDatabase? = nil,
        calendar: Calendar = Calendar(identifier: .gregorian),
        nowProvider: @escaping () -> Date = Date.init,
        dayZeroWriter: DayZeroWriter? = nil
    ) throws {
        self.databaseWriter = database
        self.cloudDatabase = cloudDatabase
        self.calendar = calendar
        self.nowProvider = nowProvider
        self.dayZeroWriter = dayZeroWriter ?? LocalStore.defaultDayZeroWriter
        try migrateIfNeeded()
    }

    /// Open a production-grade `DatabasePool` at `path`. Configures a 5-second
    /// busy timeout so the WidgetKit and Live Activity processes that share
    /// the App Group SQLite file don't crash on contention, and explicitly
    /// asserts WAL journaling so concurrent reader/writer access is safe.
    static func openProductionPool(atPath path: String) throws -> DatabasePool {
        var configuration = Configuration()
        configuration.busyMode = .timeout(5.0)
        let pool = try DatabasePool(path: path, configuration: configuration)
        try pool.write { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        return pool
    }

    // MARK: - PROFILE singleton + atomic bootstrap

    /// Atomically inserts the singleton PROFILE row and the day-0
    /// WITHDRAWAL_STATE row in a single GRDB transaction. Throws
    /// `LocalStoreError.profileAlreadyBootstrapped` if a profile already exists.
    /// Either both rows land or neither does — see
    /// `test_bootstrapProfile_rollsBackBothRowsOnDayZeroFailure`.
    func bootstrapProfile(_ draft: ProfileDraft) throws -> Profile {
        let (profile, deltas) = try databaseWriter.write { db -> (Profile, [CloudDelta]) in
            if try ProfileRow.fetchOne(db) != nil {
                throw LocalStoreError.profileAlreadyBootstrapped
            }
            let profileRow = LocalStore.makeProfileRow(from: draft)
            try profileRow.save(db)
            let withdrawalRow = try dayZeroWriter(db, draft)
            return (
                Profile(from: profileRow),
                [.save(profileRow.toCKRecord()), .save(withdrawalRow.toCKRecord())]
            )
        }
        propagate(deltas)
        return profile
    }

    func upsertProfile(_ profile: ProfileRow) throws {
        guard profile.recordName == ProfileRow.singletonRecordName else {
            throw LocalStoreError.profileMustUseSingletonID
        }
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            let existing = try ProfileRow.fetchOne(db)
            if let existing, existing.recordName != profile.recordName {
                throw LocalStoreError.profileAlreadyExists
            }
            try profile.save(db)
            return [.save(profile.toCKRecord())]
        }
        propagate(deltas)
    }

    // MARK: - simple per-row upserts

    func upsertWeightLog(_ row: WeightLogRow) throws { try saveAndPropagate(row) }
    func upsertLiftSession(_ row: LiftSessionRow) throws { try saveAndPropagate(row) }
    func upsertLiftLog(_ row: LiftLogRow) throws { try saveAndPropagate(row) }
    func upsertSwimSession(_ row: SwimSessionRow) throws { try saveAndPropagate(row) }
    func upsertWalkSession(_ row: WalkSessionRow) throws { try saveAndPropagate(row) }
    func upsertUrgeLog(_ row: UrgeLogRow) throws { try saveAndPropagate(row) }
    func upsertRotation(_ row: RotationRow) throws { try saveAndPropagate(row) }
    func upsertGroceryList(_ row: GroceryListRow) throws { try saveAndPropagate(row) }

    // MARK: - HYDRATION_LOG with wall-clock daily window

    func upsertHydrationLog(_ row: HydrationLogRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            var row = row
            let startOfDay = calendar.startOfDay(for: row.loggedAt)
            // Bucket by the user's wall-clock calendar day, not UTC.
            // SQLite's `date(logged_at)` would mis-bucket sips logged near
            // local midnight when the UTC date has already rolled over.
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw CocoaError(.coderInvalidValue)
            }
            let total = try Int.fetchOne(
                db,
                sql: """
                    SELECT COALESCE(SUM(oz), 0)
                    FROM hydration_log
                    WHERE logged_at >= ? AND logged_at < ?
                    """,
                arguments: [startOfDay, endOfDay]
            ) ?? 0
            row.runningTotalOzCached = total + row.oz
            try row.save(db)
            return [.save(row.toCKRecord())]
        }
        propagate(deltas)
    }

    // MARK: - MEAL_LOG ⊕ DEVIATION_LOG mutex (symmetric)

    func upsertMealLog(_ row: MealLogRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            let deviationCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM deviation_log WHERE meal_date = ?",
                arguments: [row.mealDate]
            ) ?? 0
            if deviationCount > 0 {
                throw LocalStoreError.mealLogConflictsWithDeviation(mealDate: row.mealDate)
            }
            var row = row
            if let existing = try MealLogRow.fetchOne(
                db,
                sql: "SELECT * FROM meal_log WHERE meal_date = ?",
                arguments: [row.mealDate]
            ) {
                row.id = existing.id
            }
            try row.save(db)
            return [.save(row.toCKRecord())]
        }
        propagate(deltas)
    }

    func upsertDeviationLog(_ row: DeviationLogRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            var deltas: [CloudDelta] = []
            if let meal = try MealLogRow.fetchOne(
                db,
                sql: "SELECT * FROM meal_log WHERE meal_date = ?",
                arguments: [row.mealDate]
            ) {
                try meal.delete(db)
                deltas.append(.delete(MealLogRow.recordID(for: meal.id)))
            }
            try row.save(db)
            deltas.append(.save(row.toCKRecord()))
            return deltas
        }
        propagate(deltas)
    }

    // MARK: - SMOKE_CHECK + RELAPSE_LOG

    func upsertSmokeCheck(_ row: SmokeCheckRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            var row = row
            if let existing = try SmokeCheckRow.fetchOne(
                db,
                sql: "SELECT * FROM smoke_check WHERE check_date = ?",
                arguments: [row.checkDate]
            ) {
                row.id = existing.id
            }
            try row.save(db)
            var deltas: [CloudDelta] = [.save(row.toCKRecord())]
            if let profileDelta = try recomputeCleanStreakDays(db: db) {
                deltas.append(profileDelta)
            }
            return deltas
        }
        propagate(deltas)
    }

    func upsertRelapseLog(_ row: RelapseLogRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            let checkDate = PersistenceDate.calendarDateString(from: row.loggedAt, calendar: calendar)
            guard let smokeCheck = try SmokeCheckRow.fetchOne(
                db,
                sql: "SELECT * FROM smoke_check WHERE check_date = ? AND answer = 'relapse'",
                arguments: [checkDate]
            ) else {
                throw LocalStoreError.relapseRequiresRelapseSmokeCheck
            }
            var row = row
            row.smokeCheckID = smokeCheck.id
            try row.save(db)
            return [.save(row.toCKRecord())]
        }
        propagate(deltas)
    }

    // MARK: - WITHDRAWAL_STATE day-1..7 gate

    func upsertWithdrawalState(_ row: WithdrawalStateRow) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            guard let profile = try ProfileRow.fetchOne(db),
                  let quitDate = parseCalendarDate(profile.quitDate) else {
                return []
            }
            let today = calendar.startOfDay(for: nowProvider())
            let days = calendar.dateComponents([.day], from: quitDate, to: today).day ?? -1
            guard (1...7).contains(days) else { return [] }
            try row.save(db)
            return [.save(row.toCKRecord())]
        }
        propagate(deltas)
    }
}

// MARK: - cloud propagation (post-commit, fire-and-forget)

private extension LocalStore {
    /// Best-effort CloudKit propagation. Errors are intentionally swallowed:
    /// the GRDB transaction has already committed and the offline-first
    /// contract requires the public API to succeed once the local row lands.
    /// A future sub-task will replace this with the persistent retry queue
    /// referenced in `design.v3 §sync engine`.
    func propagate(_ deltas: [CloudDelta]) {
        guard let cloud = cloudDatabase else { return }
        for delta in deltas {
            switch delta {
            case .save(let record):
                try? cloud.save(record: record)
            case .delete(let recordID):
                try? cloud.delete(recordID: recordID)
            }
        }
    }
}

// MARK: - small helpers

private extension LocalStore {
    /// Save a simple-shape row + collect its CKRecord delta. The deferred
    /// `chore(persistence)` PR will replace this if-let chain with a
    /// `CloudSyncable` protocol so callers can drop the type-specific switch.
    func saveAndPropagate<T: PersistableRecord>(_ row: T) throws {
        let deltas = try databaseWriter.write { db -> [CloudDelta] in
            try row.save(db)
            return Self.cloudSaveDelta(for: row).map { [$0] } ?? []
        }
        propagate(deltas)
    }

    static func cloudSaveDelta<T: PersistableRecord>(for row: T) -> CloudDelta? {
        if let row = row as? WeightLogRow { return .save(row.toCKRecord()) }
        if let row = row as? LiftSessionRow { return .save(row.toCKRecord()) }
        if let row = row as? LiftLogRow { return .save(row.toCKRecord()) }
        if let row = row as? SwimSessionRow { return .save(row.toCKRecord()) }
        if let row = row as? WalkSessionRow { return .save(row.toCKRecord()) }
        if let row = row as? UrgeLogRow { return .save(row.toCKRecord()) }
        if let row = row as? RotationRow { return .save(row.toCKRecord()) }
        if let row = row as? GroceryListRow { return .save(row.toCKRecord()) }
        return nil
    }

    func recomputeCleanStreakDays(db: Database) throws -> CloudDelta? {
        guard var profile = try ProfileRow.fetchOne(db) else { return nil }
        var streak = 0
        var cursorDate = calendar.startOfDay(for: nowProvider())
        while true {
            let dateString = PersistenceDate.calendarDateString(from: cursorDate, calendar: calendar)
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM smoke_check WHERE check_date = ? AND answer = 'clean'",
                arguments: [dateString]
            ) ?? 0
            if count == 0 { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursorDate) else { break }
            cursorDate = previous
        }
        profile.cleanStreakDays = streak
        try profile.save(db)
        return .save(profile.toCKRecord())
    }

    func parseCalendarDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: value) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func makeProfileRow(from draft: ProfileDraft) -> ProfileRow {
        ProfileRow(
            recordName: ProfileRow.singletonRecordName,
            heightIn: draft.heightIn,
            sex: draft.sex,
            age: draft.age,
            startWeightLb: draft.startWeightLb,
            goalWeightLb: draft.goalWeightLb,
            wakeTime: draft.wakeTime,
            mealWindowStart: draft.mealWindowStart,
            mealWindowEnd: draft.mealWindowEnd,
            bedTime: draft.bedTime,
            kcalTarget: draft.kcalTarget,
            proteinTargetG: draft.proteinTargetG,
            quitDate: draft.quitDate,
            whySentence: draft.whySentence,
            triggersJSON: draft.triggersJSON,
            cleanStreakDays: 0,
            currentWeightLbCached: draft.startWeightLb,
            adherencePctCached: 0
        )
    }

    static let defaultDayZeroWriter: DayZeroWriter = { db, draft in
        let row = WithdrawalStateRow(
            id: UUID(),
            withdrawalDay: 0,
            asOfDate: draft.quitDate,
            currentHeroWord: "Day 1",
            isWorstDay: false
        )
        try row.save(db)
        return row
    }
}
