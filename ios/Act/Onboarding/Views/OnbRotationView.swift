import SwiftUI

/// Step 8 — "Eat." Week-1 rotation seed, weeks 2–4 collapsed. Editing the
/// rotation is a Settings-era feature; onboarding only confirms the seed.
struct OnbRotationView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}

    private let weekOneDishes = ["Salmon coconut curry", "Beef chili"]
    private let collapsedWeeks = ["Week 2", "Week 3", "Week 4"]

    var body: some View {
        OnbShell(
            hero: "Eat.",
            sub: "Week 1 of 4",
            ctaTitle: "Looks good",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            VStack(spacing: 0) {
                openWeek
                ForEach(Array(collapsedWeeks.enumerated()), id: \.element) { index, week in
                    weekHeader(week, isOpen: false)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            if index < collapsedWeeks.count - 1 {
                                ACTTokens.hairline.frame(height: 1)
                            }
                        }
                }
            }
        }
    }

    private var openWeek: some View {
        VStack(alignment: .leading, spacing: 8) {
            weekHeader("Week 1", isOpen: true)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(weekOneDishes, id: \.self) { dish in
                    Text(dish)
                        .font(ACTTokens.TYPE.text(.s14))
                        .foregroundStyle(ACTTokens.textDim)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            ACTTokens.hairline.frame(height: 1)
        }
    }

    private func weekHeader(_ title: String, isOpen: Bool) -> some View {
        HStack {
            Text(title)
                .font(ACTTokens.TYPE.text(.s16, weight: isOpen ? .bold : .medium))
                .foregroundStyle(isOpen ? ACTTokens.text : ACTTokens.textDim)
            Spacer(minLength: 0)
            Text(isOpen ? "−" : "+")
                .font(ACTTokens.TYPE.mono(.s13))
                .foregroundStyle(ACTTokens.textMute)
        }
    }
}

#Preview {
    OnbRotationView()
}
