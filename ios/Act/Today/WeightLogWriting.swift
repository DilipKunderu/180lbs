import Foundation

/// Write seam for the weigh-in flow: the narrow surface `TodayCoordinatorModel`
/// needs to persist a weigh-in, analogous to `OnboardingProfileStore` for the
/// onboarding bootstrap. Injecting the protocol (not the concrete `LocalStore`)
/// lets model tests use a spy with no GRDB. `LocalStore` conforms in
/// `LocalStore+TodayWrite.swift` (its existing `upsertWeightLog` satisfies it).
protocol WeightLogWriting: AnyObject {
    func upsertWeightLog(_ row: WeightLogRow) throws
}
