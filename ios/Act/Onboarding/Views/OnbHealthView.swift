import SwiftUI

/// Step 3 — "Health." Lists the HealthKit read/write scopes before the
/// system prompt. When the user leaves this step, `OnboardingCoordinatorModel`
/// fires a best-effort `requestAuthorization()` call through the injected
/// `HealthAuthorizationRequesting` seam (backed by `HealthKitService` in production).
struct OnbHealthView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}

    private let readTypes = ["Weight", "Steps", "Sleep", "Resting HR", "HRV", "VO2 max"]
    private let writeTypes = ["Workouts", "Dietary energy", "Dietary water"]

    var body: some View {
        OnbShell(
            hero: "Health.",
            sub: "Connect Apple Health",
            ctaTitle: "Allow",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            VStack(alignment: .leading, spacing: 0) {
                OnbSectionLabel(text: "Read")
                    .padding(.bottom, 4)
                rows(readTypes)
                OnbSectionLabel(text: "Write")
                    .padding(.top, 18)
                    .padding(.bottom, 4)
                rows(writeTypes)
            }
        }
    }

    private func rows(_ keys: [String]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                OnbRow(key: key, isLast: index == keys.count - 1)
            }
        }
    }
}

#Preview {
    OnbHealthView()
}
