import SwiftUI

/// Step 7 — "Quit." The only data-entry screen: trigger chips and the
/// why-sentence. Copy register is locked (design.v3 §Hard lines): honest,
/// no shame language. The CTA *is* the commitment — "I am a non-smoker."
struct OnbQuitView: View {
    /// JSX label ↔ stored snake_case raw value (string-equality join with
    /// RELAPSE_LOG.trigger post-hoc, per the interface sketch).
    static let triggerOptions: [(label: String, rawValue: String)] = [
        ("Social invitation", "social_invite"),
        ("Stress", "stress"),
        ("Boredom", "boredom"),
        ("After dinner", "ritual"),
        ("Specific person", "specific_person"),
        ("Specific place", "specific_place")
    ]

    var selectedTriggers: Set<String> = []
    var whySentence: Binding<String> = .constant("")
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}
    var onToggleTrigger: (String) -> Void = { _ in }

    var body: some View {
        OnbShell(
            hero: "Quit.",
            sub: "Today is Day 0. Zero hookah from this moment.",
            ctaTitle: "I am a non-smoker.",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    OnbSectionLabel(text: "Triggers")
                    OnbChipFlow(spacing: 8) {
                        ForEach(Self.triggerOptions, id: \.rawValue) { option in
                            chip(option)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    OnbSectionLabel(text: "Your why")
                    TextField(
                        "",
                        text: whySentence,
                        prompt: Text("One sentence — why are you quitting?")
                            .foregroundStyle(ACTTokens.textMute)
                    )
                    .font(ACTTokens.TYPE.mono(.s14))
                    .foregroundStyle(ACTTokens.text)
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        ACTTokens.hairline.frame(height: 1)
                    }
                }
            }
        }
    }

    private func chip(_ option: (label: String, rawValue: String)) -> some View {
        let isOn = selectedTriggers.contains(option.rawValue)
        return Button {
            onToggleTrigger(option.rawValue)
        } label: {
            Text(option.label)
                .font(ACTTokens.TYPE.text(.s13, weight: .medium))
                .foregroundStyle(isOn ? ACTTokens.limeText : ACTTokens.textDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isOn {
                        Capsule().fill(ACTTokens.lime)
                    } else {
                        Capsule().strokeBorder(ACTTokens.hairline2, lineWidth: 1)
                    }
                }
        }
    }
}

#Preview {
    OnbQuitView(selectedTriggers: ["stress", "ritual"])
}
