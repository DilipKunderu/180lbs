import SwiftUI

/// Step 9 — "Shop." Final step; the CTA completes onboarding (bootstraps
/// the profile). Sending to Reminders is a later integration sub-task.
struct OnbGroceryView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}

    private let categories: [(name: String, count: Int)] = [
        ("Proteins", 6),
        ("Grains", 3),
        ("Produce", 11),
        ("Dairy", 2),
        ("Pantry", 8)
    ]

    var body: some View {
        OnbShell(
            hero: "Shop.",
            sub: "Saturday list, ready.",
            ctaTitle: "Send to Reminders",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.name) { index, category in
                    OnbRow(
                        key: category.name,
                        value: "\(category.count) items",
                        isLast: index == categories.count - 1
                    )
                }
            }
        }
    }
}

#Preview {
    OnbGroceryView()
}
