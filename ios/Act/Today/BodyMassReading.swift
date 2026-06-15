import Foundation

/// The provenance of a WEIGHT_LOG row: how the weight value reached the app.
///
/// Stored as its `rawValue` string in the `source` column per design.v5
/// §Data model (`source` = "healthkit | manual_pad").
enum WeightLogSource: String {
    /// The value originated from a HealthKit body-mass sample (pre-fill path).
    case healthkit
    /// The user typed the value on the manual weight pad.
    case manualPad = "manual_pad"
}

/// Read seam for HealthKit body-mass pre-fill. Renderer-free; no HealthKit
/// import at this layer so the protocol is testable without an entitlement.
///
/// Returns `nil` on denial, no-data, or any error — callers must treat `nil`
/// as "show the manual pad" per design.v5 §Failure modes ("HealthKit
/// authorization denied"). The real anchored body-mass query is a deferred
/// follow-up; until then the production conformance is `StubBodyMassReader`.
protocol BodyMassReading: Sendable {
    /// Returns the user's most-recent body-mass reading in pounds, or `nil`
    /// when no reading is available or HealthKit is not authorized.
    func latestBodyMassLb() async -> Double?
}

/// Production stub: always returns `nil`, landing the UI on the manual pad.
/// Replace with a real HealthKit anchored query in a follow-up sub-task.
struct StubBodyMassReader: BodyMassReading {
    func latestBodyMassLb() async -> Double? { nil }
}
