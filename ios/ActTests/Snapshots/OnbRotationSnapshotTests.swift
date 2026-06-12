import XCTest
@testable import Act

final class OnbRotationSnapshotTests: SnapshotTestCase {
    func test_onbRotation_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbRotationView(showsBackLink: true))
    }
}
