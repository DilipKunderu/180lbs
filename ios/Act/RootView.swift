import SwiftUI

/// Root of the view hierarchy: black while loading (no spinner — the design
/// does not own a loading pattern), onboarding for a fresh install, Today
/// for a returning user. `ContentView` stands in for the Today coordinator
/// until that sub-task lands.
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
                ContentView()
            }
        }
        .onAppear {
            model.load()
        }
    }
}
