import SwiftUI

/// "Naked row" from the design JSX: key left, optional mono value right,
/// hairline divider below unless the row is last. No cards, ever.
struct OnbRow: View {
    let key: String
    var value = ""
    var isLast = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(key)
                .font(ACTTokens.TYPE.text(.s16, weight: .medium))
                .foregroundStyle(ACTTokens.text)
            Spacer(minLength: 0)
            Text(value)
                .font(ACTTokens.TYPE.mono(.s14))
                .foregroundStyle(ACTTokens.textDim)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                ACTTokens.hairline.frame(height: 1)
            }
        }
    }
}

/// Uppercase mono section label (e.g. "TRIGGERS", "9 STEPS").
struct OnbSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(ACTTokens.TYPE.mono(.s11))
            .kerning(1.2)
            .foregroundStyle(ACTTokens.textMute)
    }
}

/// Mono text link used for secondary actions ("Manual for now →").
/// Deliberately not a button shape — the lime CTA is the only button.
struct OnbTextLink: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ACTTokens.TYPE.mono(.s13))
                .kerning(0.4)
                .foregroundStyle(ACTTokens.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }
}
