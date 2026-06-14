import XCTest
@testable import Act

/// Pins the onboarding step sequence (GAP-ONB-2). Reordering or renumbering a
/// case silently breaks `OnboardingFlowModel`'s rawValue±1 navigation and the
/// design.v5 §Flow 4 step order, so the exact 9-step sequence is locked here.
final class OnboardingStepTests: XCTestCase {
    func test_allCases_areTheNineDesignStepsInOrder() {
        XCTAssertEqual(OnboardingStep.allCases, [
            .welcome, .profile, .health, .notifications, .scale,
            .hydration, .quit, .rotation, .grocery
        ])
        XCTAssertEqual(OnboardingStep.allCases.map(\.rawValue), Array(0...8))
    }
}
