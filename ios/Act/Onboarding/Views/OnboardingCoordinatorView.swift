import SwiftUI

/// Renders the Onb* screen for the model's current step and wires every
/// CTA / back link / data binding into `OnboardingCoordinatorModel`. All
/// flow logic lives in the model; this view is a switch.
struct OnboardingCoordinatorView: View {
    let model: OnboardingCoordinatorModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch model.step {
        case .welcome:
            OnbWelcomeView(onCTA: model.advance)
        case .profile:
            OnbProfileView(
                builder: model.flowModel.draftBuilder,
                showsBackLink: model.showsBackLink,
                onBack: model.back,
                onCTA: model.advance
            )
        case .health:
            OnbHealthView(showsBackLink: model.showsBackLink, onBack: model.back, onCTA: model.advance)
        case .notifications:
            OnbNotificationsView(showsBackLink: model.showsBackLink, onBack: model.back, onCTA: model.advance)
        case .scale:
            OnbScaleView(
                showsBackLink: model.showsBackLink,
                onBack: model.back,
                onCTA: model.advance,
                onManual: model.advance
            )
        case .hydration:
            OnbHydrationView(
                showsBackLink: model.showsBackLink,
                onBack: model.back,
                onCTA: model.advance,
                onBuy: { openURL(OnboardingLinks.hidrateStore) },
                onManual: model.advance
            )
        case .quit:
            quitView
        case .rotation:
            OnbRotationView(showsBackLink: model.showsBackLink, onBack: model.back, onCTA: model.advance)
        case .grocery:
            OnbGroceryView(showsBackLink: model.showsBackLink, onBack: model.back, onCTA: model.advance)
        }
    }

    private var quitView: some View {
        @Bindable var flowModel = model.flowModel
        return OnbQuitView(
            selectedTriggers: Set(flowModel.draftBuilder.triggers),
            whySentence: $flowModel.draftBuilder.whySentence,
            showsBackLink: model.showsBackLink,
            onBack: model.back,
            onCTA: model.advance,
            onToggleTrigger: { trigger in
                if let index = flowModel.draftBuilder.triggers.firstIndex(of: trigger) {
                    flowModel.draftBuilder.triggers.remove(at: index)
                } else {
                    flowModel.draftBuilder.triggers.append(trigger)
                }
            }
        )
    }
}

enum OnboardingLinks {
    /// Hidrate Spark PRO store page ("Buy one ($65) →" on OnbHydration).
    static let hidrateStore = URL(string: "https://hidratespark.com") ?? URL(fileURLWithPath: "/")
}
