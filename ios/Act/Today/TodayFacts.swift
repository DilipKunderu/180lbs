import Foundation

/// An immutable snapshot of the facts `TodayCoordinator.resolve` needs to
/// determine the current `TodayState`.
///
/// Anchors (`wakeTime`, `mealWindowStart`, `bedTime`) are stored as
/// `DateComponents` (hour + minute only) — date-free and timezone-free —
/// so the same snapshot is valid for any "today".  The `LocalStore` read
/// seam parses ProfileRow "HH:mm" strings into these components before
/// vending the snapshot; the resolver reconstructs today's anchor `Date`
/// by splicing each component onto `now`'s y/m/d via the injected calendar.
struct TodayFacts: Equatable {
    /// The current wall-clock moment, injected so the resolver is pure.
    var now: Date
    /// Wall-clock wake anchor (hour + minute only; no date, no timezone).
    var wakeTime: DateComponents
    /// Wall-clock meal-window-start anchor (hour + minute only).
    var mealWindowStart: DateComponents
    /// Wall-clock bed-time anchor (hour + minute only).
    var bedTime: DateComponents
    /// `true` when a `WEIGHT_LOG` row whose local-calendar day == today exists.
    var weighInLogged: Bool
}
