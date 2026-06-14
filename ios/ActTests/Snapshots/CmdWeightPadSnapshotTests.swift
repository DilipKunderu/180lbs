import XCTest
@testable import Act

final class CmdWeightPadSnapshotTests: SnapshotTestCase {
    /// Renders the pad in the stale state: "STALE · TAP TO ENTER" tag visible,
    /// a representative weight value displayed in large SF Mono, and the lime
    /// "Good." CTA pinned at the bottom. This is the primary shipped state for
    /// users whose HealthKit read returns nil (StubBodyMassReader path).
    func test_cmdWeightPad_stale_renders_dark_iphone13pro() {
        assertViewSnapshot(CmdWeightPad(weightDisplay: "185.0"))
    }
}
