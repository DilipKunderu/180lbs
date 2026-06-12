import Foundation

/// Renderer-free seam between the onboarding layer and HealthKit.
///
/// `OnboardingCoordinatorModel` depends on this protocol rather than on
/// `HealthKitService` directly, keeping the onboarding layer free of any
/// HealthKit import. `HealthKitService` conforms to this protocol in the
/// service layer (sub-task 2), which is the only sanctioned `HKHealthStore`
/// path in the app.
///
/// Per `design.v3.md §Failure modes`, a denial or any thrown error is treated
/// as success at the call site — the flow advances unconditionally and the
/// error is swallowed with `try?`.
public protocol HealthAuthorizationRequesting: Sendable {
    /// Request HealthKit read/write authorization. May throw on a hard
    /// system error; denial completes without throwing (existing HealthKitService
    /// contract, pinned by `test_requestAuthorization_completes_evenWhenStoreCallsBackWithFalse`).
    func requestAuthorization() async throws
}
