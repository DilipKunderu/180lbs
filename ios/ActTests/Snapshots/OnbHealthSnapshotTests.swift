import XCTest
@testable import Act

final class OnbHealthSnapshotTests: SnapshotTestCase {
    func test_onbHealth_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbHealthView(showsBackLink: true))
    }
}
