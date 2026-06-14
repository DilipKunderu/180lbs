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
    /// DELIBERATELY-WRONG STUB — always returns `.preWake` so the red gate
    /// shows real assertion failures rather than build errors.
    /// AUTHOR_CODE (sub-task 1 green) replaces this body with the real
    /// anchor reconstruction + weekday derivation logic.
    static func resolve(_ facts: TodayFacts, calendar: Calendar) -> TodayState {
        .preWake
    }
}
