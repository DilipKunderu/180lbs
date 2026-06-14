import Foundation
@testable import Act

/// Programmable in-memory `TodayFactsReading` for `TodayCoordinatorModel`
/// tests — no GRDB, no disk. The `facts` property is settable so a test can
/// flip `weighInLogged` to simulate a write landing (e.g. verify the
/// write→re-resolve loop terminates at the right state).
final class FakeTodayFactsReader: TodayFactsReading {
    /// The snapshot returned by every `todayFacts(now:)` call.
    /// Mutate between calls to simulate a state change (e.g. flip
    /// `facts.weighInLogged = true` after a write to drive re-resolve).
    var facts: TodayFacts

    init(facts: TodayFacts) {
        self.facts = facts
    }

    func todayFacts(now: Date) throws -> TodayFacts {
        // Ignore `now`; the caller already controls the clock via `nowProvider`.
        facts
    }
}
