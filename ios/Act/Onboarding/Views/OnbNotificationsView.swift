import SwiftUI

/// Step 4 — "Push." Previews the daily notification schedule. Registration
/// is the notification-scheduling service's job in a later sub-task; this
/// screen only sets expectations before the system prompt.
struct OnbNotificationsView: View {
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}

    private let schedule: [(time: String, label: String)] = [
        ("5:00", "Weigh-in"),
        ("5:15", "Pre-workout"),
        ("7:00", "Post-workout 16oz"),
        ("17:30", "Reheat"),
        ("18:00", "Eat"),
        ("19:00", "Walk"),
        ("21:00", "Sleep")
    ]

    var body: some View {
        OnbShell(
            hero: "Push.",
            sub: "7 a day. Useful ones.",
            ctaTitle: "Allow",
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA
        ) {
            VStack(spacing: 0) {
                ForEach(Array(schedule.enumerated()), id: \.element.label) { index, entry in
                    scheduleRow(entry, isLast: index == schedule.count - 1)
                }
            }
        }
    }

    private func scheduleRow(_ entry: (time: String, label: String), isLast: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(entry.time)
                .font(ACTTokens.TYPE.mono(.s13))
                .foregroundStyle(ACTTokens.textMute)
                .frame(width: 48, alignment: .leading)
            Text(entry.label)
                .font(ACTTokens.TYPE.text(.s16, weight: .medium))
                .foregroundStyle(ACTTokens.text)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                ACTTokens.hairline.frame(height: 1)
            }
        }
    }
}

#Preview {
    OnbNotificationsView()
}
