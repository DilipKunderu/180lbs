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

    // E3: HK's mL → fluid-ounce conversion can drift sub-ULP; identical sips
    // must still collapse under a 0.01 oz tolerance.
    func test_deduplicate_collapsesBottleAndManualWithinFluidOunceConversionTolerance() {
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .hidrateSpark
        )
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 5.9999999,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [bottle, manualTap])

        XCTAssertEqual(deduped, [bottle])
    }

    // W8: bottle sample arrives AFTER manual tap → bottle wins, manual evicted.
    func test_deduplicate_evictsManualTapWhenBottleArrivesAfter() {
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .manualTap
        )
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:30Z"),
            oz: 6.0,
            source: .hidrateSpark
        )

        let deduped = deduplicate(samples: [manualTap, bottle])

        XCTAssertEqual(deduped, [bottle])
    }

    // W9: pin the boundary at exactly 60.0 seconds (inclusive).
    func test_deduplicate_collapsesAtExactlyOneMinuteBoundary() {
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .hidrateSpark
        )
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:01:00Z"),
            oz: 6.0,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [bottle, manualTap])

        XCTAssertEqual(deduped, [bottle])
    }

    func test_deduplicate_keepsManualTypedInterleavedWithBottleAndManualTap() {
        let bottle = HydrationSample(
            loggedAt: date("2026-05-22T12:00:00Z"),
            oz: 6.0,
            source: .hidrateSpark
        )
        let manualTyped = HydrationSample(
            loggedAt: date("2026-05-22T12:00:15Z"),
            oz: 6.0,
            source: .manualTyped
        )
        let manualTap = HydrationSample(
            loggedAt: date("2026-05-22T12:00:30Z"),
            oz: 6.0,
            source: .manualTap
        )

        let deduped = deduplicate(samples: [bottle, manualTyped, manualTap])

        XCTAssertEqual(deduped.sorted { $0.loggedAt < $1.loggedAt }, [bottle, manualTyped])
    }

    // E4: Hidrate publishes under com.hidratenow.* in current shipping builds;
    // legacy com.hidrate.* is kept as a defensive fallback until TestFlight
    // confirms which prefix the paired bottle actually emits.
    func test_resolveSource_recognizesBothHidrateBundlePrefixes() {
        XCTAssertEqual(
            HealthKitService.resolveSource(fromBundleID: "com.hidratenow.app", metadataSourceTag: nil),
            .hidrateSpark
        )
        XCTAssertEqual(
            HealthKitService.resolveSource(fromBundleID: "com.hidrate.spark", metadataSourceTag: nil),
            .hidrateSpark
        )
        XCTAssertEqual(
            HealthKitService.resolveSource(fromBundleID: "com.apple.health", metadataSourceTag: "manual_tap"),
            .manualTap
        )
        XCTAssertEqual(
            HealthKitService.resolveSource(fromBundleID: "com.apple.health", metadataSourceTag: nil),
            .manualTyped
        )
    }

    // E2: requestAuthorization completes silently whether the user accepts or
    // denies — Apple does not surface a read-denial signal. The service must
    // not throw on a (false, nil) callback.
    func test_requestAuthorization_completes_evenWhenStoreCallsBackWithFalse() async throws {
        let healthStore = MockHealthStore()
        healthStore.requestAuthorizationSuccess = false
        let service = HealthKitService(healthStore: healthStore)

        try await service.requestAuthorization()

        XCTAssertEqual(healthStore.requestAuthorizationCallCount, 1)
    }

    func test_authorizationStatus_writeType_passesThroughFromHealthStore() async {
        let healthStore = MockHealthStore()
        healthStore.writeStatuses[HealthKitWriteType.dietaryWater.sampleType.identifier] = .sharingAuthorized
        let service = HealthKitService(healthStore: healthStore)

        let status = await service.authorizationStatus(for: .dietaryWater)

        XCTAssertEqual(status, .sharingAuthorized)
    }

    // W7: stopping the hydration observer must also disable background delivery
    // so HK does not keep waking the app on bottle sips.
    func test_stopHydrationObserver_disablesBackgroundDelivery() async {
        let healthStore = MockHealthStore()
        let service = HealthKitService(healthStore: healthStore)

        await service.startHydrationObserver(onUpdate: {})
        await service.stopHydrationObserver()

        XCTAssertEqual(healthStore.disableBackgroundDeliveryCallCount, 1)
        XCTAssertEqual(healthStore.stoppedQueryCount, 1)
    }

    func test_observer_callback_routesToActorOnUpdateHandler() async {
        let healthStore = MockHealthStore()
        let service = HealthKitService(healthStore: healthStore)
        let counter = LockedCounter()

        await service.startHydrationObserver(onUpdate: { counter.increment() })
        await service._testFireHydrationObserverCallback()

        XCTAssertEqual(counter.count, 1)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let parsed = formatter.date(from: value) else {
            fatalError("invalid test date: \(value)")
        }
        return parsed
    }
}

private final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    // @unchecked Sendable so the actor service can hold us across awaits.
    // Mutable counters are guarded by the lock below.
    private let lock = NSLock()
    private var _requestAuthorizationSuccess = true
    private var _requestAuthorizationError: Error?
    private var _writeStatuses: [String: HKAuthorizationStatus] = [:]
    private var _requestAuthorizationCallCount = 0
    private var _executedQueryCount = 0
    private var _stoppedQueryCount = 0
    private var _enableBackgroundDeliveryCallCount = 0
    private var _disableBackgroundDeliveryCallCount = 0

    var requestAuthorizationSuccess: Bool {
        get { lock.withLock { _requestAuthorizationSuccess } }
        set { lock.withLock { _requestAuthorizationSuccess = newValue } }
    }

    var requestAuthorizationError: Error? {
        get { lock.withLock { _requestAuthorizationError } }
        set { lock.withLock { _requestAuthorizationError = newValue } }
    }

    var writeStatuses: [String: HKAuthorizationStatus] {
        get { lock.withLock { _writeStatuses } }
        set { lock.withLock { _writeStatuses = newValue } }
    }

    var requestAuthorizationCallCount: Int { lock.withLock { _requestAuthorizationCallCount } }
    var executedQueryCount: Int { lock.withLock { _executedQueryCount } }
    var stoppedQueryCount: Int { lock.withLock { _stoppedQueryCount } }
    var enableBackgroundDeliveryCallCount: Int { lock.withLock { _enableBackgroundDeliveryCallCount } }
    var disableBackgroundDeliveryCallCount: Int { lock.withLock { _disableBackgroundDeliveryCallCount } }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        let (success, error) = lock.withLock { () -> (Bool, Error?) in
            _requestAuthorizationCallCount += 1
            return (_requestAuthorizationSuccess, _requestAuthorizationError)
        }
        completion(success, error)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        lock.withLock { _writeStatuses[type.identifier] ?? .notDetermined }
    }

    func execute(_ query: HKQuery) {
        lock.withLock { _executedQueryCount += 1 }
    }

    func stop(_ query: HKQuery) {
        lock.withLock { _stoppedQueryCount += 1 }
    }

    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        lock.withLock { _enableBackgroundDeliveryCallCount += 1 }
        completion(true, nil)
    }

    func disableBackgroundDelivery(
        for type: HKObjectType,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        lock.withLock { _disableBackgroundDeliveryCallCount += 1 }
        completion(true, nil)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int {
        lock.withLock { _count }
    }

    func increment() {
        lock.withLock { _count += 1 }
    }
}
