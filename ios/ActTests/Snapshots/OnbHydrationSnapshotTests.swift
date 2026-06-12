import XCTest
@testable import Act

final class OnbHydrationSnapshotTests: SnapshotTestCase {
    func test_onbHydration_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbHydrationView(showsBackLink: true))
    }
}
