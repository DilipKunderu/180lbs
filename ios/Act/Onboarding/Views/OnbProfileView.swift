import SwiftUI

/// Step 2 — "You." Seed profile rows, rendered from the draft builder's
/// defaults so the screen and the persisted draft cannot disagree.
struct OnbProfileView: View {
    var builder = ProfileDraftBuilder()
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}

    var body: some View {
        OnbShell(
            hero: "You.",
            ctaTitle: "Confirm",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            let draft = builder.build()
            VStack(spacing: 0) {
                OnbRow(key: "Height", value: formatHeight(inches: draft.heightIn))
                OnbRow(key: "Sex", value: draft.sex)
                OnbRow(key: "Age", value: "\(draft.age)")
                OnbRow(key: "Weight", value: "\(Int(draft.startWeightLb)) lb")
                OnbRow(key: "Goal", value: "\(Int(draft.goalWeightLb))", isLast: true)
            }
        }
    }

    private func formatHeight(inches: Int) -> String {
        "\(inches / 12)'\(inches % 12)\""
    }
}

#Preview {
    OnbProfileView()
}
