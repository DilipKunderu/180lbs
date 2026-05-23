import CloudKit
import Foundation
import GRDB

final class LocalStore {
    private let databaseQueue: DatabaseQueue
    private let cloudDatabase: CloudDatabase?
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(cloudDatabase: CloudDatabase? = nil) throws {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.act.coach")?
            .appendingPathComponent("act.sqlite") else {
            throw CocoaError(.fileNoSuchFile)
        }
        databaseQueue = try DatabaseQueue(path: url.path)
        self.cloudDatabase = cloudDatabase
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        self.calendar = calendar
        self.nowProvider = Date.init
        try migrateIfNeeded()
    }

    init(
        databaseQueue: DatabaseQueue,
        cloudDatabase: CloudDatabase? = nil,
        calendar: Calendar = Calendar(identifier: .gregorian),
        nowProvider: @escaping () -> Date = Date.init
    ) throws {
        self.databaseQueue = databaseQueue
        self.cloudDatabase = cloudDatabase
        self.calendar = calendar
        self.nowProvider = nowProvider
        try migrateIfNeeded()
    }

    func upsertProfile(_ profile: ProfileRow) throws {
        guard profile.recordName == ProfileRow.singletonRecordName else {
            throw LocalStoreError.profileMustUseSingletonID
        }
        try databaseQueue.write { db in
            let existing = try ProfileRow.fetchOne(db)
            if let existing, existing.recordName != profile.recordName {
                throw LocalStoreError.profileAlreadyExists
            }
            try profile.save(db)
            try cloudDatabase?.save(record: profile.toCKRecord())
        }
    }

    func upsertWeightLog(_ row: WeightLogRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertLiftSession(_ row: LiftSessionRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertLiftLog(_ row: LiftLogRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertSwimSession(_ row: SwimSessionRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertWalkSession(_ row: WalkSessionRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertHydrationLog(_ row: HydrationLogRow) throws {
        try databaseQueue.write { db in
            var row = row
            let day = PersistenceDate.calendarDateString(from: row.loggedAt, calendar: calendar)
            let total = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(SUM(oz), 0) FROM hydration_log WHERE date(logged_at) = date(?)",
                arguments: [PersistenceDate.iso8601.string(from: row.loggedAt)]
            ) ?? 0
            row.runningTotalOzCached = total + row.oz
            try row.save(db)
            try cloudDatabase?.save(record: row.toCKRecord())

            _ = day
        }
    }

    func upsertMealLog(_ row: MealLogRow) throws {
        try databaseQueue.write { db in
            var row = row
            if let existing = try MealLogRow.fetchOne(db, sql: "SELECT * FROM meal_log WHERE meal_date = ?", arguments: [row.mealDate]) {
                row.id = existing.id
            }
            try row.save(db)
            try cloudDatabase?.save(record: row.toCKRecord())
        }
    }

    func upsertDeviationLog(_ row: DeviationLogRow) throws {
        try databaseQueue.write { db in
            if let meal = try MealLogRow.fetchOne(db, sql: "SELECT * FROM meal_log WHERE meal_date = ?", arguments: [row.mealDate]) {
                try meal.delete(db)
                try cloudDatabase?.delete(recordID: MealLogRow.recordID(for: meal.id))
            }
            try row.save(db)
            try cloudDatabase?.save(record: row.toCKRecord())
        }
    }

    func upsertSmokeCheck(_ row: SmokeCheckRow) throws {
        try databaseQueue.write { db in
            var row = row
            if let existing = try SmokeCheckRow.fetchOne(
                db,
                sql: "SELECT * FROM smoke_check WHERE check_date = ?",
                arguments: [row.checkDate]
            ) {
                row.id = existing.id
            }
            try row.save(db)
            try cloudDatabase?.save(record: row.toCKRecord())
            try recomputeCleanStreakDays(db: db)
        }
    }

    func upsertRelapseLog(_ row: RelapseLogRow) throws {
        try databaseQueue.write { db in
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
            try cloudDatabase?.save(record: row.toCKRecord())
        }
    }

    func upsertUrgeLog(_ row: UrgeLogRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertRotation(_ row: RotationRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertGroceryList(_ row: GroceryListRow) throws {
        try saveRecord(row) { try $0.save($1) }
    }

    func upsertWithdrawalState(_ row: WithdrawalStateRow) throws {
        try databaseQueue.write { db in
            guard let profile = try ProfileRow.fetchOne(db),
                  let quitDate = parseCalendarDate(profile.quitDate) else {
                return
            }
            let today = calendar.startOfDay(for: nowProvider())
            let days = calendar.dateComponents([.day], from: quitDate, to: today).day ?? -1
            guard (1...7).contains(days) else { return }
            try row.save(db)
            try cloudDatabase?.save(record: row.toCKRecord())
        }
    }

    private func saveRecord<T>(_ row: T, store: (T, Database) throws -> Void) throws where T: PersistableRecord {
        try databaseQueue.write { db in
            try store(row, db)
            if let row = row as? WeightLogRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? LiftSessionRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? LiftLogRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? SwimSessionRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? WalkSessionRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? UrgeLogRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? RotationRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            } else if let row = row as? GroceryListRow {
                try cloudDatabase?.save(record: row.toCKRecord())
            }
        }
    }

    private func recomputeCleanStreakDays(db: Database) throws {
        guard var profile = try ProfileRow.fetchOne(db) else { return }
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
        try cloudDatabase?.save(record: profile.toCKRecord())
    }

    private func parseCalendarDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: value) else { return nil }
        return calendar.startOfDay(for: date)
    }

}

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
        try migrator.migrate(databaseQueue)
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
