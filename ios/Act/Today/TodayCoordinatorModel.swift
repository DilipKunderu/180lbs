import Foundation
import Observation

/// Drives the Today surface: builds a `TodayFacts` snapshot via the injected
/// reader, resolves it to a `TodayState`, and writes a weigh-in via the
/// injected writer — then re-resolves so the UI moves past `.weighIn`.
///
/// Renderer-free on purpose — no SwiftUI import. The coordinator view binds
/// to this model; tests exercise it directly against fake seams.
///
/// The model owns one `Calendar` (injected at construction). In production
/// that calendar is the `LocalStore`'s calendar, so the reader and resolver
/// agree on the same timezone and the same day-boundary near local midnight.
@Observable
final class TodayCoordinatorModel {

    // MARK: - Observable state

    private(set) var state: TodayState = .preWake
    private(set) var prefilledWeightLb: Double?

    // MARK: - @ObservationIgnored async drain handle

    /// Retained handle for the most-recent body-mass read Task. Set
    /// synchronously in `loadBodyMass()` before the async work completes,
    /// so tests can `await model.bodyMassTask?.value` to drain it
    /// deterministically — identical contract to
    /// `OnboardingCoordinatorModel.healthAuthorizationTask`.
    @ObservationIgnored private(set) var bodyMassTask: Task<Void, Never>?

    // MARK: - Injected seams

    private let reader: any TodayFactsReading
    private let writer: any WeightLogWriting
    private let bodyMass: any BodyMassReading
    private let calendar: Calendar
    private let nowProvider: () -> Date

    // MARK: - Init

    init(
        reader: any TodayFactsReading,
        writer: any WeightLogWriting,
        bodyMass: any BodyMassReading = StubBodyMassReader(),
        calendar: Calendar,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.reader = reader
        self.writer = writer
        self.bodyMass = bodyMass
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    // MARK: - Public interface (stubs — production bodies shipped in AUTHOR_CODE)

    /// Re-read `TodayFacts` from the injected reader and re-resolve `state`.
    /// STUB: does nothing — tests will fail red until the production body lands.
    func refresh() {
        // TODO: read facts via reader + resolve + set state
    }

    /// Fire the async body-mass read into `bodyMassTask` and, once it
    /// completes, set `prefilledWeightLb`.
    /// STUB: does nothing — tests will fail red until the production body lands.
    func loadBodyMass() {
        // TODO: fire Task { prefilledWeightLb = await bodyMass.latestBodyMassLb() }
    }

    /// Write a weigh-in row via the injected writer then call `refresh()` to
    /// re-resolve state so the UI moves past `.weighIn`.
    /// STUB: does nothing — tests will fail red until the production body lands.
    func logWeighIn(lb: Double) throws {
        // TODO: build WeightLogRow, call writer.upsertWeightLog, then refresh()
    }
}
