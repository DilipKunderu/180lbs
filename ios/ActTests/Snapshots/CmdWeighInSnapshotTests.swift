import XCTest
@testable import Act

final class CmdWeighInSnapshotTests: SnapshotTestCase {
    /// Pre-filled state: HealthKit (or cache) supplied a body-mass value.
    /// Verifies: "Weigh." hero, "308.4" in large SF Mono, "LBS" unit label,
    /// and the single lime "Good." sticky CTA.
    func test_cmdWeighIn_prefilled_renders_dark_iphone13pro() {
        assertViewSnapshot(CmdWeighIn(prefilledWeightLb: 308.4, onGood: { _, _ in }))
    }

    /// Stale / manual state: HealthKit denied or no data — `prefilledWeightLb`
    /// is `nil`. Verifies: `CmdWeightPad` fallback is rendered ("STALE · TAP
    /// TO ENTER" tag, empty numeric display, full keypad, lime "Good." CTA).
    func test_cmdWeighIn_manualPad_renders_dark_iphone13pro() {
        assertViewSnapshot(CmdWeighIn(prefilledWeightLb: nil, onGood: { _, _ in }))
    }
}
