import XCTest
@testable import Act

final class OnbProfileSnapshotTests: SnapshotTestCase {
    func test_onbProfile_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbProfileView(showsBackLink: true))
    }
}
