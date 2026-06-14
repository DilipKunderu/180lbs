import Foundation

/// A pure, renderer-free resolver that maps a `TodayFacts` snapshot to the
/// single `TodayState` that should be active right now.
///
/// No SwiftUI, no GRDB, no side-effects — only value-in / value-out so the
/// full transition table is covered by plain XCTest unit tests.
///
/// - Note: `resolve` accepts an injected `calendar: Calendar` so tests can
///   pin a fixed timezone and make weekday/anchor math deterministic,
///   regardless of the host machine's `TimeZone.current`.
///   Production callers pass `Calendar(identifier: .gregorian)` with
///   `TimeZone.current` already set (the default for `Calendar.current`).
enum TodayCoordinator {
    static func resolve(_ facts: TodayFacts, calendar: Calendar) -> TodayState {
        // 1. Reconstruct today's wake anchor as a full Date in the injected calendar's zone.
        //    Pull y/m/d from `facts.now`, splice in the hour/minute from the anchor, then
        //    rehydrate.  If calendar.date(from:) returns nil (malformed components —
        //    should never happen for valid ProfileRow data) we treat now as past-wake
        //    and continue to the weigh-in gate.
        var ymd = calendar.dateComponents([.year, .month, .day], from: facts.now)
        ymd.hour   = facts.wakeTime.hour
        ymd.minute = facts.wakeTime.minute
        ymd.second = 0
        let wakeAnchor = calendar.date(from: ymd) ?? facts.now

        // 2. Pre-wake gate.
        if facts.now < wakeAnchor {
            return .preWake
        }

        // 3. Weigh-in gate — must be cleared before anything else.
        if !facts.weighInLogged {
            return .weighIn
        }

        // 4. Lift-day gate — weekday derived from the injected calendar so
        //    timezone is correct (tests pin America/Los_Angeles; production
        //    uses Calendar.current which carries TimeZone.current).
        //    Gregorian: Sun=1 Mon=2 Tue=3 Wed=4 Thu=5 Fri=6 Sat=7
        //    Lift days: Mon=2 / Wed=4 / Fri=6
        let weekday = calendar.component(.weekday, from: facts.now)
        let isLiftDay = weekday == 2 || weekday == 4 || weekday == 6
        return isLiftDay ? .preWorkout : .fasting
    }
}
