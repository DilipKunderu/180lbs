import Foundation
import GRDB

// MARK: - TodayFactsReading conformance

extension LocalStore: TodayFactsReading {
    /// Returns a `TodayFacts` snapshot for the given `now`.
    ///
    /// - `weighInLogged`: true when any WEIGHT_LOG row's `logged_at` falls in
    ///   the local calendar day of `now`, bucketed identically to
    ///   `upsertHydrationLog` (startOfDay … startOfDay+1day).
    /// - `wakeTime` / `mealWindowStart` / `bedTime`: parsed from the singleton
    ///   PROFILE row's "HH:mm" strings into hour+minute `DateComponents`. When
    ///   no profile row exists (defensive path — Today only runs post-onboarding)
    ///   the anchors are empty `DateComponents()`.
    func todayFacts(now: Date) throws -> TodayFacts {
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw CocoaError(.coderInvalidValue)
        }

        return try databaseWriter.read { db in
            // --- weighInLogged ---
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM weight_log WHERE logged_at >= ? AND logged_at < ?",
                arguments: [startOfDay, endOfDay]
            ) ?? 0
            let weighInLogged = count > 0

            // --- anchors from PROFILE ---
            guard let profile = try ProfileRow.fetchOne(db) else {
                return TodayFacts(
                    now: now,
                    wakeTime: DateComponents(),
                    mealWindowStart: DateComponents(),
                    bedTime: DateComponents(),
                    weighInLogged: weighInLogged
                )
            }

            return TodayFacts(
                now: now,
                wakeTime: parseHHmm(profile.wakeTime),
                mealWindowStart: parseHHmm(profile.mealWindowStart),
                bedTime: parseHHmm(profile.bedTime),
                weighInLogged: weighInLogged
            )
        }
    }
}

// MARK: - private helpers

private extension LocalStore {
    /// Parse an "HH:mm" string into `DateComponents(hour:minute:)`.
    /// Returns an empty `DateComponents()` on a malformed input — valid
    /// profiles always carry "HH:mm", so this is a safety net only.
    func parseHHmm(_ value: String) -> DateComponents {
        let parts = value.split(separator: ":", maxSplits: 1)
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return DateComponents()
        }
        return DateComponents(hour: hour, minute: minute)
    }
}
