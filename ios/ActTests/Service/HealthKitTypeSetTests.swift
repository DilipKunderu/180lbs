import XCTest
@testable import Act

/// Pins the HealthKit authorization scopes (GAP-HK-1) to design.v5
/// §Integrations so a silently-added case can't request a permission the
/// design never sanctioned. Read: body mass, steps, sleep, resting HR, HRV,
/// VO2 max, dietary water. Write: workouts, dietary energy, dietary water.
final class HealthKitTypeSetTests: XCTestCase {
    func test_readTypeSet_matchesDesignV5() {
        XCTAssertEqual(HealthKitReadType.allCases.count, 7)
        for expected: HealthKitReadType in [
            .bodyMass, .stepCount, .sleepAnalysis, .restingHeartRate,
            .heartRateVariabilitySDNN, .vo2Max, .dietaryWater
        ] {
            XCTAssertTrue(HealthKitReadType.allCases.contains(expected),
                          "missing read type \(expected)")
        }
    }

    func test_writeTypeSet_matchesDesignV5() {
        XCTAssertEqual(HealthKitWriteType.allCases.count, 3)
        for expected: HealthKitWriteType in [.workouts, .dietaryEnergyConsumed, .dietaryWater] {
            XCTAssertTrue(HealthKitWriteType.allCases.contains(expected),
                          "missing write type \(expected)")
        }
    }
}
