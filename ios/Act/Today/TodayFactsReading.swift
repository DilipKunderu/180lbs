import Foundation

/// Read seam that vends a `TodayFacts` snapshot to `TodayCoordinatorModel`.
///
/// The seam is injected at construction time so coordinators and model tests
/// can use a fake reader with no GRDB dependency.  The `LocalStore` conformance
/// lives in `LocalStore+Today.swift` and is the only production implementation.
protocol TodayFactsReading: AnyObject {
    /// Build and return a `TodayFacts` snapshot anchored to `now`.
    ///
    /// - Parameter now: The current wall-clock moment.  Callers inject this so
    ///   the method is testable with a fixed instant.
    /// - Returns: A fully-populated `TodayFacts` snapshot.
    /// - Throws: Any underlying storage error.
    func todayFacts(now: Date) throws -> TodayFacts
}
