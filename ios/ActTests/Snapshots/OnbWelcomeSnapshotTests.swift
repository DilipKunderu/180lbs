import XCTest
@testable import Act

final class OnbWelcomeSnapshotTests: SnapshotTestCase {
    func test_onbWelcome_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbWelcomeView())
    }
}
