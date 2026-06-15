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
    func disableBackgroundDelivery(
        for type: HKObjectType,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    )
}

extension HKHealthStore: HealthStoreProtocol {}

public enum HydrationSource: String, Equatable, Sendable {
    case hidrateSpark = "hidrate_spark"
    case manualTap = "manual_tap"
    case manualTyped = "manual_typed"
}

public struct HydrationSample: Equatable, Sendable {
    public let loggedAt: Date
    public let oz: Double
    public let source: HydrationSource

    public init(loggedAt: Date, oz: Double, source: HydrationSource) {
        self.loggedAt = loggedAt
        self.oz = oz
        self.source = source
    }
}

/// Volume-equality tolerance for hydration de-dup. HealthKit converts the
/// bottle's published mL into fluid ounces internally; the round-trip may drift
/// sub-ULP, so byte-exact equality would miss same-sip pairs. 0.01 oz is well
/// below any real sip size, so it never merges actually-different sips.
private let hydrationVolumeEqualityToleranceOz: Double = 0.01

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

    guard abs(lhs.oz - rhs.oz) < hydrationVolumeEqualityToleranceOz else {
        return false
    }

    let distance = abs(lhs.loggedAt.timeIntervalSince(rhs.loggedAt))
    return distance <= 60
}

/// Owns the single `HKHealthStore` for the app and serializes all HealthKit
/// query lifecycle calls through actor isolation so concurrent foreground +
/// background callers (e.g. the `HydrationMonitor` background task and the
/// foreground UI) cannot race on `hydrationObserverQuery`.
///
/// **Read-side privacy constraint (Apple).** `HKHealthStore.authorizationStatus(for:)`
/// always returns `.notDetermined` for read types — apps cannot detect whether
/// the user denied READ access. There is no `authorizationStatus(for: HealthKitReadType)`
/// on this service for that reason. The canonical workaround is to observe
/// data presence (via the anchored query / observer here) and treat absence as
/// the de-facto read-denial signal at each `Cmd*` surface (see
/// `docs/design/design.v3.md` §Integrations table).
public actor HealthKitService {
    public enum MetadataKeys {
        public static let hydrationSource = "com.act.coach.hydrationSource"
        public static let manualTap = "manual_tap"
    }

    public static let hydrationSampleType = HKQuantityType(.dietaryWater)

    /// Hidrate Inc. publishes the Spark PRO bottle's HealthKit samples under
    /// `com.hidratenow.*` in current shipping builds; `com.hidrate.*` is kept
    /// as a defensive fallback until the paired-bottle install confirms which
    /// prefix actually arrives in production. TODO: after the first TestFlight
    /// install, verify against Settings → Health → Data Access → Sources and
    /// trim this allowlist down to the single observed prefix.
    private static let hidrateBundlePrefixes: Set<String> = [
        "com.hidratenow",
        "com.hidrate"
    ]

    private let healthStore: HealthStoreProtocol
    private var hydrationObserverQuery: HKObserverQuery?
    private var hydrationObserverOnUpdate: (@Sendable () -> Void)?
    private var hydrationBackgroundDeliveryRequested = false

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

    /// Per-type WRITE authorization status. Write status is real; the caller
    /// can use this to degrade write-dependent surfaces (e.g. CmdMeal's
    /// "Logged + shake" HealthKit write). No read-side equivalent exists by
    /// Apple privacy design — see the type-level doc comment.
    public func authorizationStatus(for type: HealthKitWriteType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type.sampleType)
    }

    public func startHydrationObserver(onUpdate: @Sendable @escaping () -> Void) {
        if let existing = hydrationObserverQuery {
            healthStore.stop(existing)
        }
        hydrationObserverOnUpdate = onUpdate

        let query = HKObserverQuery(sampleType: Self.hydrationSampleType, predicate: nil) { [weak self] _, completion, error in
            defer { completion() }
            guard error == nil else { return }
            Task { await self?.handleObserverFired() }
        }

        hydrationObserverQuery = query
        healthStore.execute(query)

        // Background hydration wakeups improve freshness accuracy (the 30/60-min
        // `HydrationMonitor` escalation per design.v3 §Stateful surfaces — see
        // "Hydration freshness state machine" — depends on continuous-ish samples
        // from the bottle) but consume BGAppRefreshTask budget more aggressively
        // on high-frequency sip days. Kept ON by default for the service-layer PR;
        // the throttling-vs-foreground-catchup vs Today-state-gated decision moves
        // to the schedule-planner sub-task where the cost is measurable against the
        // nightly notification re-registration budget.
        healthStore.enableBackgroundDelivery(for: Self.hydrationSampleType, frequency: .immediate) { _, _ in }
        // Treat this as requested, not confirmed: HK may reject asynchronously,
        // and disableBackgroundDelivery is idempotent for non-enabled types.
        hydrationBackgroundDeliveryRequested = true
    }

    public func stopHydrationObserver() {
        if let existing = hydrationObserverQuery {
            healthStore.stop(existing)
            hydrationObserverQuery = nil
        }
        hydrationObserverOnUpdate = nil

        if hydrationBackgroundDeliveryRequested {
            healthStore.disableBackgroundDelivery(for: Self.hydrationSampleType) { _, _ in }
            hydrationBackgroundDeliveryRequested = false
        }
    }

    public func fetchHydrationSamplesSince(
        anchor: HKQueryAnchor?
    ) async throws -> (samples: [HydrationSample], newAnchor: HKQueryAnchor) {
        typealias HydrationFetchResult = (samples: [HydrationSample], newAnchor: HKQueryAnchor)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HydrationFetchResult, Error>) in
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
                let mapped = hydrationSamples.map(Self.makeHydrationSample(from:))
                continuation.resume(returning: (mapped, newAnchor ?? HKQueryAnchor(fromValue: 0)))
            }

            healthStore.execute(query)
        }
    }

    /// Most-recent HealthKit body-mass reading in pounds, or `nil` on
    /// denial / no-data / any error (fail-open per `design.v5 §Failure modes`).
    ///
    /// NOTE: the `HKSampleQuery` + `execute(...)` boundary below is intentionally
    /// untested — `HKQuantitySample` has no public initializer and the test
    /// `MockHealthStore.execute(_:)` is a counter-only stub that never fires a
    /// query's results handler, so this wrapper cannot be exercised at the
    /// `HealthStoreProtocol` seam. The selection + kg→lb logic IS covered by
    /// `BodyMassTests` via the pure `latestBodyMassLb(from:)` converter; this
    /// wrapper only maps `HKQuantitySample` → `(date, kg)` and delegates.
    public func latestBodyMassLb() async -> Double? {
        let bodyMassType = HKQuantityType(.bodyMass)
        let samples: [HKQuantitySample]? = try? await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (results as? [HKQuantitySample]) ?? [])
            }
            healthStore.execute(query)
        }
        guard let samples else { return nil }
        let tuples = samples.map { (date: $0.endDate, kg: $0.quantity.doubleValue(for: .gramUnit(with: .kilo))) }
        // Module-qualified to disambiguate from this instance method of the same base name.
        return Act.latestBodyMassLb(from: tuples)
    }

    func _testFireHydrationObserverCallback() {
        handleObserverFired()
    }

    private func handleObserverFired() {
        hydrationObserverOnUpdate?()
    }

    private static func makeHydrationSample(from sample: HKQuantitySample) -> HydrationSample {
        let metadataSourceTag = sample.metadata?[MetadataKeys.hydrationSource] as? String
        return HydrationSample(
            loggedAt: sample.endDate,
            oz: sample.quantity.doubleValue(for: .fluidOunceUS()),
            source: resolveSource(
                fromBundleID: sample.sourceRevision.source.bundleIdentifier,
                metadataSourceTag: metadataSourceTag
            )
        )
    }

    /// Pure source-resolution helper. Exposed at module scope (internal) so
    /// tests can exercise the bundle-ID + metadata mapping rules without
    /// constructing `HKSource` (which has no public initializer).
    static func resolveSource(fromBundleID bundleID: String, metadataSourceTag: String?) -> HydrationSource {
        let normalized = bundleID.lowercased()
        for prefix in hidrateBundlePrefixes where normalized == prefix || normalized.hasPrefix(prefix + ".") {
            return .hidrateSpark
        }

        if metadataSourceTag == MetadataKeys.manualTap {
            return .manualTap
        }

        return .manualTyped
    }
}

// MARK: - HealthAuthorizationRequesting seam
// `requestAuthorization()` already satisfies the protocol verbatim; this
// extension wires the service-layer actor into the onboarding-layer protocol
// without naming `HealthKitService` anywhere in the onboarding layer.
extension HealthKitService: HealthAuthorizationRequesting {}

// MARK: - BodyMassReading seam
// `latestBodyMassLb()` satisfies the protocol verbatim; this wires the service
// actor into the Today-layer protocol without naming `HealthKitService` there.
extension HealthKitService: BodyMassReading {}
