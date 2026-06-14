import Foundation

// `LocalStore.upsertWeightLog(_:)` (in LocalStore.swift) already has the exact
// signature `WeightLogWriting` requires — refreshing current_weight_lb_cached +
// adherence and propagating one PROFILE delta — so this conformance is empty.
extension LocalStore: WeightLogWriting {}
