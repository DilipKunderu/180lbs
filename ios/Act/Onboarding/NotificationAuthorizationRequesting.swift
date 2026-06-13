import Foundation

/// Renderer-free seam between the onboarding layer and local-notification
/// permission.
///
/// `OnboardingCoordinatorModel` depends on this protocol rather than on
/// `UNUserNotificationCenter` directly, keeping the onboarding layer free of any
/// UserNotifications import. `NotificationService` conforms to this protocol in
/// the service layer, which is the only sanctioned `UNUserNotificationCenter`
/// authorization path in the app.
///
/// Scope: this requests the *permission* prompt only. Registering the scheduled
/// notification set (the 7 fixed-daily + 7 D1-D7 + weekly-insight + ad-hoc
/// hydration-critical notifications) is explicitly deferred to a future
/// notification-scheduling subsystem per `design.v5.md §Flow 4` and the
/// onboarding-interface sketch — onboarding never registers notifications.
///
/// Per `design.v5.md §Failure modes`, a denial or any thrown error is treated
/// as success at the call site — the flow advances unconditionally and the
/// error is swallowed with `try?` (the "Push." re-prompt path handles a later
/// retry).
public protocol NotificationAuthorizationRequesting: Sendable {
    /// Request local-notification authorization (the system permission sheet).
    /// May throw on a hard system error; a user denial completes without
    /// throwing.
    func requestAuthorization() async throws
}
