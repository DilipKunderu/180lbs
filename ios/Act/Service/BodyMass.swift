import Foundation

/// Kilograms-to-pounds conversion factor (exact per international pound definition).
let kgToLbFactor: Double = 2.2046226218

/// Selects the most-recent body-mass sample by date and converts its value
/// from kilograms to pounds.
///
/// This is a pure, HealthKit-free helper so it can be exercised in unit tests
/// without constructing `HKQuantitySample` (which has no public initialiser).
/// The caller is responsible for mapping real `HKQuantitySample` values into
/// the plain `(date:kg:)` tuple before passing them here.
///
/// - Parameter samples: Zero or more `(date, kg)` pairs in any order.
/// - Returns: The lb value of the sample with the latest `date`, or `nil` when
///   `samples` is empty.
func latestBodyMassLb(from samples: [(date: Date, kg: Double)]) -> Double? {
    guard let latest = samples.max(by: { $0.date < $1.date }) else { return nil }
    return latest.kg * kgToLbFactor
}
