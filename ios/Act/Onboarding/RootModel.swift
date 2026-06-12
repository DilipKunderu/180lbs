import Foundation
import Observation

/// Root routing state: resolves loading / onboarding / today via
/// `RootDestination.resolve` and owns the onboarding coordinator model's
/// lifetime so `RootView` stays a dumb switch.
///
/// `store` is optional because `LocalStore()` can fail at app launch (App
/// Group container unavailable); that degrades to the `.loading` black
/// screen, same as a failed profile read.
@Observable
final class RootModel {
    private(set) var destination: RootDestination = .loading
    let onboardingModel: OnboardingCoordinatorModel?

    private let store: OnboardingProfileStore?

    init(store: OnboardingProfileStore?) {
        self.store = store
        self.onboardingModel = store.map { OnboardingCoordinatorModel(store: $0) }
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
