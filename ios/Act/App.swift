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

        // Build one LocalStore instance and pass it as both the onboarding store
        // and the Today read/write seams — LocalStore conforms to both
        // OnboardingProfileStore, TodayFactsReading, and WeightLogWriting.
        // Sharing one instance ensures the reader and coordinator resolve on the
        // same calendar (localStore.calendar), per the architect steering note
        // in the plan (plans/today-coordinator-cmdweighin.md §Architecture).
        let localStore = try? LocalStore()
        _rootModel = State(initialValue: RootModel(
            store: localStore,
            healthAuthorizer: healthAuthorizer,
            notificationAuthorizer: notificationAuthorizer,
            todayReader: localStore,
            todayWriter: localStore,
            bodyMass: StubBodyMassReader(),
            calendar: localStore?.calendar ?? {
                var c = Calendar(identifier: .gregorian)
                c.timeZone = .current
                return c
            }()
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: rootModel)
        }
    }
}
