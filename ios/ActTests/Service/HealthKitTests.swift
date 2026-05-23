import Foundation
import HealthKit
import XCTest
@testable import Act

final class HealthKitTests: XCTestCase {
    func test_deduplicate_dropsManualTapWithin60sOfSameVolumeBottleSample() {
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .hidrateSpark
        )
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:00:30Z"),
            oz: 6.0,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [bottle, manualTap])

        XCTAssertEqual(deduped, [bottle])
    }

    func test_deduplicate_keepsManualTapMoreThan60sFromBottleSample() {
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .hidrateSpark
        )
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:01:01Z"),
            oz: 6.0,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [bottle, manualTap])

        XCTAssertEqual(deduped, [bottle, manualTap])
    }

    func test_deduplicate_keepsTwoBottleSamples30sApart() {
        let firstBottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 2.0,
            source: .hidrateSpark
        )
        let secondBottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:30Z"),
            oz: 2.0,
            source: .hidrateSpark
        )

        let deduped = deduplicate(samples: [firstBottle, secondBottle])

        XCTAssertEqual(deduped, [firstBottle, secondBottle])
    }

    func test_deduplicate_keepsManualTapSameVolumeDifferentMinutes() {
        let firstTap = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 1.0,
            source: .manualTap
        )
        let secondTap = HydrationSample(
            loggedAt: date("2026-05-22T12:02:00Z"),
            oz: 1.0,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [firstTap, secondTap])

        XCTAssertEqual(deduped, [firstTap, secondTap])
    }

    func test_requestAuthorization_doesNotThrowWhenUserDenies() async throws {
        let healthStore = MockHealthStore()
        healthStore.requestAuthorizationSuccess = false
        healthStore.readStatuses[HealthKitReadType.bodyMass.objectType.identifier] = .sharingDenied
        let service = HealthKitService(healthStore: healthStore)

        try await service.requestAuthorization()

        XCTAssertEqual(
            service.authorizationStatus(for: .bodyMass),
            .sharingDenied
        )
        XCTAssertEqual(healthStore.requestAuthorizationCallCount, 1)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let parsed = formatter.date(from: value) else {
            fatalError("invalid test date: \(value)")
        }
        return parsed
    }
}

private final class MockHealthStore: HealthStoreProtocol {
    var requestAuthorizationSuccess = true
    var requestAuthorizationError: Error?
    var requestAuthorizationCallCount = 0
    var readStatuses: [String: HKAuthorizationStatus] = [:]
    var writeStatuses: [String: HKAuthorizationStatus] = [:]
    var executedQueries: [HKQuery] = []
    var stoppedQueries: [HKQuery] = []

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        requestAuthorizationCallCount += 1
        completion(requestAuthorizationSuccess, requestAuthorizationError)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        readStatuses[type.identifier] ?? writeStatuses[type.identifier] ?? .notDetermined
    }

    func execute(_ query: HKQuery) {
        executedQueries.append(query)
    }

    func stop(_ query: HKQuery) {
        stoppedQueries.append(query)
    }

    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        completion(true, nil)
    }
}
