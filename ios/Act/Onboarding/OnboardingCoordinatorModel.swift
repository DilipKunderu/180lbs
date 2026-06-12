import Foundation
import Observation

/// Drives the Onb* views: step progression (delegated to `OnboardingFlowModel`),
/// quit-date stamping, and the bootstrap handoff when the flow completes.
///
/// Renderer-free on purpose — no SwiftUI import. The coordinator *view* binds
/// to this model; tests exercise it directly against a fake store.
@Observable
final class OnboardingCoordinatorModel {
    let flowModel: OnboardingFlowModel
    private(set) var bootstrapFailed = false

    @ObservationIgnored var onFinished: ((Profile) -> Void)?
    private let store: OnboardingProfileStore
    private let nowProvider: () -> Date
    private let dayFormatter: DateFormatter

    init(
        store: OnboardingProfileStore,
        flowModel: OnboardingFlowModel = OnboardingFlowModel(),
        nowProvider: @escaping () -> Date = Date.init,
        timeZone: TimeZone = .current
    ) {
        self.store = store
        self.flowModel = flowModel
        self.nowProvider = nowProvider

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        self.dayFormatter = formatter

        flowModel.onComplete = { [weak self] in
            self?.completeOnboarding()
        }
    }

    var step: OnboardingStep { flowModel.step }
    var showsBackLink: Bool { flowModel.showsBackLink }

    /// The single sticky CTA. Leaving `.quit` is the "I am a non-smoker."
    /// moment — Day 0 is stamped from the injected clock right here, never
    /// earlier (the user may sit on the screen across midnight).
    func advance() {
        if flowModel.step == .quit {
            flowModel.draftBuilder.quitDate = dayFormatter.string(from: nowProvider())
        }
        flowModel.advance()
    }

    func back() {
        flowModel.back()
    }

    private func completeOnboarding() {
        do {
            let profile = try store.bootstrapProfile(flowModel.draftBuilder.build())
            bootstrapFailed = false
            onFinished?(profile)
        } catch {
            bootstrapFailed = true
        }
    }
}
