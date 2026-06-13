import SwiftUI

@main
struct ActApp: App {
    @State private var rootModel: RootModel

    init() {
        #if DEBUG
        // UI tests pass this to walk onboarding from a fresh-install state.
        if CommandLine.arguments.contains("-ActResetLocalStore") {
            LocalStore.removeProductionDatabase()
        }
        // UI tests pass this to suppress the HealthKit system sheet during
        // automated onboarding walks; nil is the no-op path (no authorizer injected).
        let healthAuthorizer: (any HealthAuthorizationRequesting)? =
            CommandLine.arguments.contains("-ActSkipHealthKitAuthorization") ? nil : HealthKitService()
        // UI tests pass this to suppress the notification system sheet during
        // automated onboarding walks; nil is the no-op path (no authorizer injected).
        let notificationAuthorizer: (any NotificationAuthorizationRequesting)? =
            CommandLine.arguments.contains("-ActSkipNotificationAuthorization") ? nil : NotificationService()
        #else
        let healthAuthorizer: (any HealthAuthorizationRequesting)? = HealthKitService()
        let notificationAuthorizer: (any NotificationAuthorizationRequesting)? = NotificationService()
        #endif
        _rootModel = State(initialValue: RootModel(
            store: try? LocalStore(),
            healthAuthorizer: healthAuthorizer,
            notificationAuthorizer: notificationAuthorizer
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: rootModel)
        }
    }
}
