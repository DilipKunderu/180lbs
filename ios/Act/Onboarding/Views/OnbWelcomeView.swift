import SwiftUI

/// Step 1 — "Act." The step count is derived from `OnboardingStep` so the
/// copy can never drift from the actual flow length.
struct OnbWelcomeView: View {
    var onCTA: () -> Void = {}

    var body: some View {
        OnbShell(
            hero: "Act.",
            heroSize: .s120,
            heroKerning: -5,
            sub: "No menus. No choices.",
            ctaTitle: "Begin",
            onCTA: onCTA
        ) {
            OnbSectionLabel(text: "\(OnboardingStep.allCases.count) steps")
        }
    }
}

#Preview {
    OnbWelcomeView()
}
