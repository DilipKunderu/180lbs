import XCTest
@testable import Act

final class OnbQuitSnapshotTests: SnapshotTestCase {
    func test_onbQuit_empty_renders_dark_iphone13pro() {
        assertViewSnapshot(OnbQuitView(showsBackLink: true))
    }

    func test_onbQuit_withSelections_renders_dark_iphone13pro() {
        assertViewSnapshot(
            OnbQuitView(
                selectedTriggers: ["stress", "ritual"],
                whySentence: .constant("I want my mornings back."),
                showsBackLink: true
            )
        )
    }
}
