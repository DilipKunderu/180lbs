import Foundation

// MARK: - TodayFactsReading conformance (deliberately incomplete — AUTHOR_CODE fills this in)

extension LocalStore: TodayFactsReading {
    /// Returns a `TodayFacts` snapshot for the given `now`.
    ///
    /// This stub always vends empty `DateComponents` anchors and
    /// `weighInLogged == false` so that `LocalStoreTodayFactsTests` go red
    /// until AUTHOR_CODE implements the real calendar-day bucketing query and
    /// "HH:mm" → `DateComponents` parse.
    func todayFacts(now: Date) throws -> TodayFacts {
        TodayFacts(
            now: now,
            wakeTime: DateComponents(),
            mealWindowStart: DateComponents(),
            bedTime: DateComponents(),
            weighInLogged: false
        )
    }
}
