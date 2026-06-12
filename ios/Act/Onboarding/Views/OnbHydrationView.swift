import SwiftUI

/// Step 6 — "Sip." Hidrate Spark pairing is HealthKit-mediated and
/// opt-out; every path advances the flow.
struct OnbHydrationView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}
    var onBuy: () -> Void = {}
    var onManual: () -> Void = {}

    var body: some View {
        OnbShell(
            hero: "Sip.",
            sub: "Pair a Hidrate Spark PRO.",
            ctaTitle: "Already paired in Apple Health",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA,
            content: {
                Text("Layer 2 accountability — 120 oz daily, escalating prompts when stale.")
                    .font(ACTTokens.TYPE.text(.s14, weight: .medium))
                    .foregroundStyle(ACTTokens.textDim)
                    .lineSpacing(4)
            },
            secondary: {
                VStack(spacing: 4) {
                    OnbTextLink(title: "Buy one ($65) →", action: onBuy)
                    OnbTextLink(title: "Manual taps for now →", action: onManual)
                }
            }
        )
    }
}

#Preview {
    OnbHydrationView()
}
