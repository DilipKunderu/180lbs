import XCTest
@testable import Act

final class OnbScaleSnapshotTests: SnapshotTestCase {
    func test_onbScale_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbScaleView(showsBackLink: true))
    }
}
