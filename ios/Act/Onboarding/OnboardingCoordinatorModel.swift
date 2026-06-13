import Foundation
import Observation

/// Drives the Onb* views: step progression (delegated to `OnboardingFlowModel`),
/// quit-date stamping, health-authorization side-effect, and the bootstrap
/// handoff when the flow completes.
///
/// Renderer-free on purpose — no SwiftUI import. The coordinator *view* binds
/// to this model; tests exercise it directly against a fake store.
@Observable
final class OnboardingCoordinatorModel {
    let flowModel: OnboardingFlowModel
    private(set) var bootstrapFailed = false

    /// Retained handle for the most-recent health-authorization fire-and-forget
    /// task. Set immediately (synchronously) when the user leaves `.health`, before
    /// the async work completes, so tests can `await task?.value` to drain it
    /// deterministically.
    ///
    /// Re-entry into `.health` would overwrite this handle; iOS no-ops repeat
    /// permission sheets so no guard is needed. `nil` when no authorizer is
    /// injected (the `-ActSkipHealthKitAuthorization` path) or when the user has
    /// not yet left `.health`.
    @ObservationIgnored private(set) var healthAuthorizationTask: Task<Void, Never>?

    /// Retained handle for the most-recent notification-authorization
    /// fire-and-forget task, set synchronously when the user leaves
    /// `.notifications` (same draining contract as `healthAuthorizationTask`).
    /// `nil` when no authorizer is injected or the user has not yet left
    /// `.notifications`.
    @ObservationIgnored private(set) var notificationAuthorizationTask: Task<Void, Never>?

    @ObservationIgnored var onFinished: ((Profile) -> Void)?
    private let store: OnboardingProfileStore
    private let nowProvider: () -> Date
    private let dayFormatter: DateFormatter
    private let healthAuthorizer: (any HealthAuthorizationRequesting)?
    private let notificationAuthorizer: (any NotificationAuthorizationRequesting)?

    init(
        store: OnboardingProfileStore,
        flowModel: OnboardingFlowModel = OnboardingFlowModel(),
        nowProvider: @escaping () -> Date = Date.init,
        timeZone: TimeZone = .current,
        healthAuthorizer: (any HealthAuthorizationRequesting)? = nil,
        notificationAuthorizer: (any NotificationAuthorizationRequesting)? = nil
    ) {
        self.store = store
        self.flowModel = flowModel
        self.nowProvider = nowProvider
        self.healthAuthorizer = healthAuthorizer
        self.notificationAuthorizer = notificationAuthorizer

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

    /// The single sticky CTA. Leaving `.quit` stamps Day 0 from the injected
    /// clock (the user may sit on the screen across midnight). Leaving `.health`
    /// fires a best-effort HealthKit authorization request through the injected
    /// seam — the step advances first, unconditionally; denial and errors are
    /// swallowed per `design.v3.md §Failure modes`.
    func advance() {
        if flowModel.step == .quit {
            flowModel.draftBuilder.quitDate = dayFormatter.string(from: nowProvider())
        }

        let leavingHealth = flowModel.step == .health
        flowModel.advance()

        if leavingHealth, let authorizer = healthAuthorizer {
            healthAuthorizationTask = Task {
                try? await authorizer.requestAuthorization()
            }
        }
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
