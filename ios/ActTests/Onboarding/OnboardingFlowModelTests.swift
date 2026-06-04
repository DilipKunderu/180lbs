import XCTest
@testable import Act

final class OnboardingFlowModelTests: XCTestCase {
    func test_initialStep_isWelcome() {
        let model = OnboardingFlowModel()

        XCTAssertEqual(model.step, .welcome)
    }

    func test_advance_walksStepsInJSXOrder() {
        let expectedSteps = OnboardingStep.allCases
        let model = OnboardingFlowModel()
        var visitedSteps = [model.step]

        for _ in expectedSteps.dropFirst() {
            model.advance()
            visitedSteps.append(model.step)
        }

        XCTAssertEqual(visitedSteps, expectedSteps)
    }

    func test_back_decrementsStep() {
        let model = OnboardingFlowModel(step: .health)

        model.back()

        XCTAssertEqual(model.step, .profile)
    }

    func test_back_atWelcome_isNoOp() {
        let model = OnboardingFlowModel(step: .welcome)

        model.back()

        XCTAssertEqual(model.step, .welcome)
    }

    func test_showsBackLink_isFalseAtWelcome_trueOtherwise() {
        let welcomeModel = OnboardingFlowModel(step: .welcome)
        let profileModel = OnboardingFlowModel(step: .profile)

        XCTAssertFalse(welcomeModel.showsBackLink)
        XCTAssertTrue(profileModel.showsBackLink)
    }

    func test_isLast_isTrueOnlyAtGrocery() {
        for step in OnboardingStep.allCases where step != .grocery {
            XCTAssertFalse(OnboardingFlowModel(step: step).isLast)
        }

        XCTAssertTrue(OnboardingFlowModel(step: .grocery).isLast)
    }

    func test_advance_atGrocery_firesOnComplete() {
        let model = OnboardingFlowModel(step: .grocery)
        var completionCount = 0
        model.onComplete = { completionCount += 1 }

        model.advance()

        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(model.step, .grocery)
    }
}
