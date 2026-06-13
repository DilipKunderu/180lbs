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
        #else
        let healthAuthorizer: (any HealthAuthorizationRequesting)? = HealthKitService()
        #endif
        _rootModel = State(initialValue: RootModel(store: try? LocalStore(), healthAuthorizer: healthAuthorizer))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: rootModel)
        }
    }
}
