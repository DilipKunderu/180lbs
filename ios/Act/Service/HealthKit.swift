import Foundation
import HealthKit

public enum HealthKitReadType: CaseIterable {
    case bodyMass
    case stepCount
    case sleepAnalysis
    case restingHeartRate
    case heartRateVariabilitySDNN
    case vo2Max
    case dietaryWater

    var objectType: HKObjectType {
        switch self {
        case .bodyMass:
            HKQuantityType(.bodyMass)
        case .stepCount:
            HKQuantityType(.stepCount)
        case .sleepAnalysis:
            HKCategoryType(.sleepAnalysis)
        case .restingHeartRate:
            HKQuantityType(.restingHeartRate)
        case .heartRateVariabilitySDNN:
            HKQuantityType(.heartRateVariabilitySDNN)
        case .vo2Max:
            HKQuantityType(.vo2Max)
        case .dietaryWater:
            HKQuantityType(.dietaryWater)
        }
    }
}

public enum HealthKitWriteType: CaseIterable {
    case workouts
    case dietaryEnergyConsumed
    case dietaryWater

    var sampleType: HKSampleType {
        switch self {
        case .workouts:
            HKObjectType.workoutType()
        case .dietaryEnergyConsumed:
            HKQuantityType(.dietaryEnergyConsumed)
        case .dietaryWater:
            HKQuantityType(.dietaryWater)
        }
    }
}

protocol HealthStoreProtocol {
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    )
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func execute(_ query: HKQuery)
    func stop(_ query: HKQuery)
    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    )
}

extension HKHealthStore: HealthStoreProtocol {}

public enum HydrationSource: String, Equatable {
    case hidrateSpark = "hidrate_spark"
    case manualTap = "manual_tap"
    case manualTyped = "manual_typed"
}

public struct HydrationSample: Equatable {
    public let loggedAt: Date
    public let oz: Double
    public let source: HydrationSource

    public init(loggedAt: Date, oz: Double, source: HydrationSource) {
        self.loggedAt = loggedAt
        self.oz = oz
        self.source = source
    }
}

public func deduplicate(samples: [HydrationSample]) -> [HydrationSample] {
    let sorted = samples.sorted { lhs, rhs in
        if lhs.loggedAt == rhs.loggedAt {
            return hydrationSourcePriority(lhs.source) < hydrationSourcePriority(rhs.source)
        }
        return lhs.loggedAt < rhs.loggedAt
    }

    var deduplicated: [HydrationSample] = []

    for sample in sorted {
        switch sample.source {
        case .manualTap:
            if deduplicated.contains(where: { isManualTapBottleDuplicate(lhs: $0, rhs: sample) }) {
                continue
            }
            deduplicated.append(sample)
        case .hidrateSpark:
            if let manualIndex = deduplicated.lastIndex(where: {
                $0.source == .manualTap && isManualTapBottleDuplicate(lhs: $0, rhs: sample)
            }) {
                deduplicated.remove(at: manualIndex)
            }
            deduplicated.append(sample)
        case .manualTyped:
            deduplicated.append(sample)
        }
    }

    return deduplicated
}

private func hydrationSourcePriority(_ source: HydrationSource) -> Int {
    switch source {
    case .hidrateSpark:
        0
    case .manualTap:
        1
    case .manualTyped:
        2
    }
}

private func isManualTapBottleDuplicate(lhs: HydrationSample, rhs: HydrationSample) -> Bool {
    let sources: Set<HydrationSource> = [lhs.source, rhs.source]
    let matchingSources: Set<HydrationSource> = [.manualTap, .hidrateSpark]
    guard sources == matchingSources else {
        return false
    }

    guard lhs.oz == rhs.oz else {
        return false
    }

    let distance = abs(lhs.loggedAt.timeIntervalSince(rhs.loggedAt))
    return distance <= 60
}

public final class HealthKitService {
    public enum MetadataKeys {
        public static let hydrationSource = "com.act.coach.hydrationSource"
        public static let manualTap = "manual_tap"
    }

    public static let hydrationSampleType = HKQuantityType(.dietaryWater)

    private let healthStore: HealthStoreProtocol
    private var hydrationObserverQuery: HKObserverQuery?

    public init() {
        self.healthStore = HKHealthStore()
    }

    init(healthStore: HealthStoreProtocol) {
        self.healthStore = healthStore
    }

    public func requestAuthorization() async throws {
        let readTypes = Set(HealthKitReadType.allCases.map(\.objectType))
        let writeTypes = Set(HealthKitWriteType.allCases.map(\.sampleType))

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    public func authorizationStatus(for type: HealthKitReadType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type.objectType)
    }

    public func authorizationStatus(for type: HealthKitWriteType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type.sampleType)
    }

    public func startHydrationObserver(onUpdate: @escaping @Sendable () -> Void) {
        if let hydrationObserverQuery {
            healthStore.stop(hydrationObserverQuery)
        }

        let query = HKObserverQuery(sampleType: Self.hydrationSampleType, predicate: nil) { _, completion, error in
            defer { completion() }
            guard error == nil else { return }
            onUpdate()
        }

        hydrationObserverQuery = query
        healthStore.execute(query)

        // Background hydration wakeups improve freshness accuracy but consume
        // BGAppRefreshTask budget more aggressively on high-frequency sip days.
        healthStore.enableBackgroundDelivery(for: Self.hydrationSampleType, frequency: .immediate) { _, _ in }
    }

    public func stopHydrationObserver() {
        guard let hydrationObserverQuery else { return }
        healthStore.stop(hydrationObserverQuery)
        self.hydrationObserverQuery = nil
    }

    public func fetchHydrationSamplesSince(anchor: HKQueryAnchor?) async throws -> (samples: [HKQuantitySample], newAnchor: HKQueryAnchor) {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: Self.hydrationSampleType,
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, newAnchor, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let hydrationSamples = (samples as? [HKQuantitySample]) ?? []
                continuation.resume(returning: (hydrationSamples, newAnchor ?? HKQueryAnchor(fromValue: 0)))
            }

            healthStore.execute(query)
        }
    }

    public static func makeHydrationSample(from sample: HKQuantitySample) -> HydrationSample {
        HydrationSample(
            loggedAt: sample.endDate,
            oz: sample.quantity.doubleValue(for: .fluidOunceUS()),
            source: resolveHydrationSource(for: sample)
        )
    }

    private static func resolveHydrationSource(for sample: HKQuantitySample) -> HydrationSource {
        let bundleIdentifier = sample.sourceRevision.source.bundleIdentifier.lowercased()
        if bundleIdentifier.hasPrefix("com.hidrate.") || bundleIdentifier == "com.hidrate" {
            return .hidrateSpark
        }

        if let explicitSource = sample.metadata?[MetadataKeys.hydrationSource] as? String,
           explicitSource == MetadataKeys.manualTap {
            return .manualTap
        }

        return .manualTyped
    }
}
