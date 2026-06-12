import XCTest
@testable import Act

final class OnbNotificationsSnapshotTests: SnapshotTestCase {
    func test_onbNotifications_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbNotificationsView(showsBackLink: true))
    }
}
