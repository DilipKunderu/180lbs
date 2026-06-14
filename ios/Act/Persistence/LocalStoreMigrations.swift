import Foundation
import GRDB

/// Schema migrations for `LocalStore`. Kept in a sibling file so the main
/// `LocalStore.swift` doesn't blow past `type_body_length`. Each table maps
/// 1:1 to a CKRecord type from `design.v3.md §Data model` so a future
/// `MigrationPlan` SRP split (deferred to `chore(persistence)`) can lift this
/// extension out wholesale.
extension LocalStore {
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
        try migrator.migrate(databaseWriter)
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
            t.column("triggers", .text).notNull()
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
            t.column("triggers", .text).notNull()
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
            t.column("items", .text).notNull()
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
