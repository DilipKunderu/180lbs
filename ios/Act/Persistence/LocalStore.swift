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
    private let database: any DatabaseWriter
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
        self.database = try LocalStore.openProductionPool(atPath: url.path)
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
        self.database = database
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
        let (profile, deltas) = try database.write { db -> (Profile, [CloudDelta]) in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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
        let deltas = try database.write { db -> [CloudDelta] in
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

// MARK: - migrations

private extension LocalStore {
    func migrateIfNeeded() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_schema") { [self] db in
            try createProfileTable(in: db)
            try createWeightTable(in: db)
            try createLiftTables(in: db)
            try createSwimTable(in: db)
            try createWalkTable(in: db)
            try createHydrationTable(in: db)
            try createMealTable(in: db)
            try createDeviationTable(in: db)
            try createSmokeTable(in: db)
            try createRelapseTable(in: db)
            try createUrgeTable(in: db)
            try createRotationTable(in: db)
            try createGroceryTable(in: db)
            try createWithdrawalTable(in: db)
        }
        try migrator.migrate(database)
    }

    func createProfileTable(in db: Database) throws {
        try db.create(table: "profile") { t in
            t.column("record_name", .text).primaryKey()
            t.column("height_in", .integer).notNull()
            t.column("sex", .text).notNull()
            t.column("age", .integer).notNull()
            t.column("start_weight_lb", .double).notNull()
            t.column("goal_weight_lb", .double).notNull()
            t.column("wake_time", .text).notNull()
            t.column("meal_window_start", .text).notNull()
            t.column("meal_window_end", .text).notNull()
            t.column("bed_time", .text).notNull()
            t.column("kcal_target", .integer).notNull()
            t.column("protein_target_g", .integer).notNull()
            t.column("quit_date", .text).notNull()
            t.column("why_sentence", .text).notNull()
            t.column("triggers_json", .text).notNull()
            t.column("clean_streak_days", .integer).notNull()
            t.column("current_weight_lb_cached", .double).notNull()
            t.column("adherence_pct_cached", .double).notNull()
        }
    }

    func createWeightTable(in db: Database) throws {
        try db.create(table: "weight_log") { t in
            t.column("id", .text).primaryKey()
            t.column("logged_at", .datetime).notNull()
            t.column("weight_lb", .double).notNull()
            t.column("source", .text).notNull()
            t.column("is_morning_weigh_in", .boolean).notNull()
        }
    }

    func createLiftTables(in db: Database) throws {
        try db.create(table: "lift_session") { t in
            t.column("id", .text).primaryKey()
            t.column("session_date", .text).notNull()
            t.column("day_label", .text).notNull()
            t.column("duration_min", .integer).notNull()
            t.column("completed", .boolean).notNull()
        }
        try db.create(table: "lift_log") { t in
            t.column("id", .text).primaryKey()
            t.column("lift_session_id", .text).notNull()
            t.column("exercise", .text).notNull()
            t.column("set_number", .integer).notNull()
            t.column("weight_lb", .double).notNull()
            t.column("reps", .integer).notNull()
            t.column("rest_sec", .integer).notNull()
        }
    }

    func createSwimTable(in db: Database) throws {
        try db.create(table: "swim_session") { t in
            t.column("id", .text).primaryKey()
            t.column("started_at", .datetime).notNull()
            t.column("duration_min", .integer).notNull()
            t.column("mode", .text).notNull()
            t.column("hr_avg_bpm", .integer)
            t.column("hr_max_bpm", .integer)
        }
    }

    func createWalkTable(in db: Database) throws {
        try db.create(table: "walk_session") { t in
            t.column("id", .text).primaryKey()
            t.column("started_at", .datetime).notNull()
            t.column("duration_min", .integer).notNull()
            t.column("steps", .integer).notNull()
            t.column("is_post_meal", .boolean).notNull()
        }
    }

    func createHydrationTable(in db: Database) throws {
        try db.create(table: "hydration_log") { t in
            t.column("id", .text).primaryKey()
            t.column("logged_at", .datetime).notNull()
            t.column("oz", .integer).notNull()
            t.column("source", .text).notNull()
            t.column("running_total_oz_cached", .integer).notNull()
        }
    }

    func createMealTable(in db: Database) throws {
        try db.create(table: "meal_log") { t in
            t.column("id", .text).primaryKey()
            t.column("meal_date", .text).notNull().unique()
            t.column("logged_at", .datetime).notNull()
            t.column("dish_name", .text).notNull()
            t.column("kcal", .integer).notNull()
            t.column("protein_g", .integer).notNull()
            t.column("carbs_g", .integer).notNull()
            t.column("fat_g", .integer).notNull()
            t.column("included_shake", .boolean).notNull()
        }
    }

    func createDeviationTable(in db: Database) throws {
        try db.create(table: "deviation_log") { t in
            t.column("id", .text).primaryKey()
            t.column("meal_date", .text).notNull().unique()
            t.column("logged_at", .datetime).notNull()
            t.column("reason", .text).notNull()
            t.column("photo_url", .text)
            t.column("kcal_est", .integer).notNull()
            t.column("protein_g_est", .integer).notNull()
        }
    }

    func createSmokeTable(in db: Database) throws {
        try db.create(table: "smoke_check") { t in
            t.column("id", .text).primaryKey()
            t.column("check_date", .text).notNull().unique()
            t.column("answered_at", .datetime).notNull()
            t.column("answer", .text).notNull()
        }
    }

    func createRelapseTable(in db: Database) throws {
        try db.create(table: "relapse_log") { t in
            t.column("id", .text).primaryKey()
            t.column("smoke_check_id", .text).notNull().unique()
            t.column("logged_at", .datetime).notNull()
            t.column("trigger", .text).notNull()
            t.column("where_text", .text).notNull()
            t.column("who_with_text", .text).notNull()
            t.column("how_much", .integer).notNull()
            t.column("how_much_unit", .text).notNull()
            t.column("stress_pre", .integer).notNull()
            t.column("craving_pre", .integer).notNull()
            t.column("social_pressure_pre", .integer).notNull()
            t.column("satisfaction_post", .integer).notNull()
            t.column("regret_post", .integer).notNull()
            t.column("reflection_text", .text).notNull()
        }
    }

    func createUrgeTable(in db: Database) throws {
        try db.create(table: "urge_log") { t in
            t.column("id", .text).primaryKey()
            t.column("logged_at", .datetime).notNull()
            t.column("intensity", .integer).notNull()
            t.column("triggers_json", .text).notNull()
            t.column("did_breathing", .boolean).notNull()
            t.column("breathing_cycles_completed", .integer).notNull()
        }
    }

    func createRotationTable(in db: Database) throws {
        try db.create(table: "rotation") { t in
            t.column("id", .text).primaryKey()
            t.column("week_index", .integer).notNull()
            t.column("slot", .integer).notNull()
            t.column("dish_name", .text).notNull()
            t.column("prescribed_kcal", .integer).notNull()
            t.column("prescribed_protein_g", .integer).notNull()
            t.column("prescribed_carbs_g", .integer).notNull()
            t.column("prescribed_fat_g", .integer).notNull()
            t.column("recipe_url", .text)
        }
    }

    func createGroceryTable(in db: Database) throws {
        try db.create(table: "grocery_list") { t in
            t.column("id", .text).primaryKey()
            t.column("shop_date", .text).notNull()
            t.column("week_index", .integer).notNull()
            t.column("items_json", .text).notNull()
            t.column("sent_to_reminders", .boolean).notNull()
        }
    }

    func createWithdrawalTable(in db: Database) throws {
        try db.create(table: "withdrawal_state") { t in
            t.column("id", .text).primaryKey()
            t.column("withdrawal_day", .integer).notNull()
            t.column("as_of_date", .text).notNull()
            t.column("current_hero_word", .text).notNull()
            t.column("is_worst_day", .boolean).notNull()
        }
    }
}
