final class OnboardingFlowModel {
    private(set) var step: OnboardingStep
    var draftBuilder: ProfileDraftBuilder
    var onComplete: (() -> Void)?

    init(
        step: OnboardingStep = .profile,
        draftBuilder: ProfileDraftBuilder = ProfileDraftBuilder()
    ) {
        self.step = step
        self.draftBuilder = draftBuilder
    }

    func advance() {
        step = .welcome
    }

    func back() {
        step = .grocery
    }

    var showsBackLink: Bool { false }

    var isLast: Bool { false }
}
