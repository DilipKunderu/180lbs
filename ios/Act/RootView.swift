import SwiftUI

/// Root of the view hierarchy: black while loading (no spinner — the design
/// does not own a loading pattern), onboarding for a fresh install, Today for
/// a returning user.
///
/// Degraded rendering: if the model could not construct its coordinator model
/// (e.g. store failed to open at launch), the affected branch renders the dark
/// background only — same pattern for both onboarding-nil and todayModel-nil.
struct RootView: View {
    let model: RootModel

    var body: some View {
        ZStack {
            switch model.destination {
            case .loading:
                ACTTokens.bg.ignoresSafeArea()
            case .onboarding:
                if let onboardingModel = model.onboardingModel {
                    OnboardingCoordinatorView(model: onboardingModel)
                } else {
                    ACTTokens.bg.ignoresSafeArea()
                }
            case .today:
                if let todayModel = model.todayModel {
                    TodayCoordinatorView(model: todayModel)
                } else {
                    ACTTokens.bg.ignoresSafeArea()
                }
            }
        }
        .onAppear {
            model.load()
        }
    }
}
