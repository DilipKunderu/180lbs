import Foundation
import UserNotifications

/// The only sanctioned `UNUserNotificationCenter` authorization path in the app.
///
/// Conforms to `NotificationAuthorizationRequesting` so the onboarding layer can
/// request the local-notification permission prompt without importing
/// UserNotifications. This requests *permission* only — it never registers any
/// `UNNotificationRequest`; the scheduled notification set is owned by a future
/// notification-scheduling subsystem (`design.v5.md §Flow 4`, §Behavior and
/// schedule).
public struct NotificationService: NotificationAuthorizationRequesting {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Presents the system permission sheet. A user denial returns normally
    /// (granted == false); only a hard system error throws — both are treated
    /// as success by the caller per `design.v5.md §Failure modes`.
    public func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
}
