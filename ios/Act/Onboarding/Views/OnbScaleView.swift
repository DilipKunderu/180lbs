import SwiftUI

/// Step 5 — "Weigh." Smart-scale pairing is HealthKit-mediated; both the
/// CTA and the manual opt-out advance the flow (pairing state is read from
/// HealthKit later, not stored on the draft).
struct OnbScaleView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}
    var onManual: () -> Void = {}

    var body: some View {
        OnbShell(
            hero: "Weigh.",
            sub: "Pair a smart scale.",
            ctaTitle: "I have Withings / Eufy / Renpho",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA,
            content: {
                OnbSectionLabel(text: "Auto-syncs · 5:00 daily")
            },
            secondary: {
                OnbTextLink(title: "Manual for now →", action: onManual)
            }
        )
    }
}

#Preview {
    OnbScaleView()
}
