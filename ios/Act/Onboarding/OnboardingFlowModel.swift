import Observation

@Observable
final class OnboardingFlowModel {
    private(set) var step: OnboardingStep
    var draftBuilder: ProfileDraftBuilder
    var onComplete: (() -> Void)?

    init(
        step: OnboardingStep = .welcome,
        draftBuilder: ProfileDraftBuilder = ProfileDraftBuilder()
    ) {
        self.step = step
        self.draftBuilder = draftBuilder
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else {
            onComplete?()
            return
        }
        step = next
    }

    func back() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else {
            return
        }
        step = previous
    }

    var showsBackLink: Bool { step != .welcome }

    var isLast: Bool { step == OnboardingStep.allCases.last }
}
