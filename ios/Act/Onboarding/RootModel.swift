import Foundation
import Observation

/// Root routing state: resolves loading / onboarding / today via
/// `RootDestination.resolve` and owns the coordinator model lifetimes so
/// `RootView` stays a dumb switch.
///
/// `store` is optional because `LocalStore()` can fail at app launch (App
/// Group container unavailable); that degrades to the `.loading` black
/// screen, same as a failed profile read.
///
/// Today seams (`todayReader`, `todayWriter`, `bodyMass`) are optional for the
/// same reason: if any is nil (e.g. the store failed to open), `todayModel` is
/// nil and `RootView` renders the degraded dark background for `.today`.
@Observable
final class RootModel {
    private(set) var destination: RootDestination = .loading
    let onboardingModel: OnboardingCoordinatorModel?
    let todayModel: TodayCoordinatorModel?

    private let store: OnboardingProfileStore?

    init(
        store: OnboardingProfileStore?,
        healthAuthorizer: (any HealthAuthorizationRequesting)? = nil,
        notificationAuthorizer: (any NotificationAuthorizationRequesting)? = nil,
        todayReader: (any TodayFactsReading)? = nil,
        todayWriter: (any WeightLogWriting)? = nil,
        bodyMass: (any BodyMassReading)? = nil,
        calendar: Calendar = {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = .current
            return c
        }()
    ) {
        self.store = store
        self.onboardingModel = store.map {
            OnboardingCoordinatorModel(
                store: $0,
                healthAuthorizer: healthAuthorizer,
                notificationAuthorizer: notificationAuthorizer
            )
        }
        // Build todayModel only when all three Today seams are available.
        if let reader = todayReader, let writer = todayWriter, let bodyMass {
            self.todayModel = TodayCoordinatorModel(
                reader: reader,
                writer: writer,
                bodyMass: bodyMass,
                calendar: calendar
            )
        } else {
            self.todayModel = nil
        }

        onboardingModel?.onFinished = { [weak self] profile in
            self?.onboardingFinished(profile)
        }
    }

    func load() {
        guard let store else {
            destination = RootDestination.resolve(profile: nil, readFailed: true)
            return
        }
        do {
            destination = RootDestination.resolve(profile: try store.currentProfile(), readFailed: false)
        } catch {
            destination = RootDestination.resolve(profile: nil, readFailed: true)
        }
    }

    func onboardingFinished(_ profile: Profile) {
        destination = RootDestination.resolve(profile: profile, readFailed: false)
    }
}
