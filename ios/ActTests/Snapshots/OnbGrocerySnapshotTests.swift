import XCTest
@testable import Act

final class OnbGrocerySnapshotTests: SnapshotTestCase {
    func test_onbGrocery_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbGroceryView(showsBackLink: true))
    }
}
