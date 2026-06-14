import Foundation
@testable import Act

/// Programmable `BodyMassReading` fake for `TodayCoordinatorModel` tests.
/// Inject a non-nil value to exercise the pre-fill path; inject `nil` to
/// exercise the manual-pad fallback.
struct FakeBodyMassReader: BodyMassReading {
    var stubbedValue: Double?

    func latestBodyMassLb() async -> Double? {
        stubbedValue
    }
}
