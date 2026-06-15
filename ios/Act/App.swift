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
        // Body-mass reader resolution (DEBUG):
        // 1. `-ActFakeBodyMassLb <value>` → FixedBodyMassReader (UI tests drive the
        //    HealthKit pre-fill → "Weigh." hero deterministically).
        // 2. else `-ActSkipHealthKitAuthorization` → StubBodyMassReader (nil → pad).
        // 3. else the real HealthKitService.
        let bodyMass: any BodyMassReading = Self.debugBodyMassReader()
        #else
        let healthAuthorizer: (any HealthAuthorizationRequesting)? = HealthKitService()
        let notificationAuthorizer: (any NotificationAuthorizationRequesting)? = NotificationService()
        let bodyMass: any BodyMassReading = HealthKitService()
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
            bodyMass: bodyMass,
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

    #if DEBUG
    /// Resolves the body-mass reader for DEBUG builds: a fixed value when UI
    /// tests pass `-ActFakeBodyMassLb <value>` (drives the pre-fill hero), the
    /// nil stub under `-ActSkipHealthKitAuthorization`, else the real service.
    private static func debugBodyMassReader() -> any BodyMassReading {
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "-ActFakeBodyMassLb"),
           idx + 1 < args.count,
           let lb = Double(args[idx + 1]) {
            return FixedBodyMassReader(lb: lb)
        }
        if args.contains("-ActSkipHealthKitAuthorization") {
            return StubBodyMassReader()
        }
        return HealthKitService()
    }
    #endif
}
