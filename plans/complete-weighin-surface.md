# Complete the weigh-in surface (real HealthKit body-mass read + provenance)

Source of truth: docs/design/design.v5.md (v5)

Created 2026-06-14 from an AI planning session (team skill, AUTHOR_PLAN mode).

## Overview

The Today milestone shipped `CmdWeighIn` with a `StubBodyMassReader` that always returns
`nil`, so the screen always lands on the manual `CmdWeightPad` and never shows its
"Weigh." pre-fill hero. Two provenance deferrals were also left behind in
`TodayCoordinatorModel.logWeighIn`: `WEIGHT_LOG.source` is hardcoded `"manual_pad"` and
`is_morning_weigh_in` is hardcoded `false`. This work replaces the stub with a real
HealthKit latest-body-mass read (fail-open to `nil` per design.v5 §Failure modes
"HealthKit authorization denied → CmdWeighIn shows CmdWeightPad"), and resolves both
provenance fields per design.v5 §Data model WEIGHT_LOG (`source = healthkit | manual_pad`,
`is_morning_weigh_in = "true if within 30 min of wake_time"`). No other Cmd screens, no
"STALE · TAP TO ENTER" cached-value path (that requires a cache the milestone hasn't
built — explicitly out of scope here), no notification wiring.

## Architecture

### The testability seam (the load-bearing decision)

`HKSampleQuery` / `HKAnchoredObjectQuery` results cannot be fabricated in a unit test:
`HKQuantitySample` and `HKSource` have no public initializer, so the existing suite tests
dedup/auth/observer-routing logic but never sample parsing. We follow the pattern already
established in `HealthKitService` for `makeHydrationSample` / `resolveSource`: split the
read into a **pure converter (unit-tested)** and a **thin query-execution wrapper
(documented-untested)**.

- **Pure, unit-tested — `latestBodyMassLb(from samples:)`**: a `static` (module-internal)
  function `[(date: Date, kg: Double)] -> Double?` that selects the most-recent reading by
  date and converts kilograms → pounds, returning `nil` for an empty input. Tests drive it
  with plain tuples (no HealthKit objects), covering: empty → nil, single sample kg→lb,
  most-recent selection among several out-of-order samples, and the kg→lb conversion
  constant. This mirrors how `resolveSource` is exposed at module scope precisely so tests
  can exercise the rules without constructing un-constructible HK types.

  Rationale for the tuple seam over `[HKQuantitySample]`: it keeps the unit boundary free
  of any un-fakeable HK type, identical in spirit to `resolveSource(fromBundleID:...)`
  taking a `String` rather than an `HKSource`.

- **Thin, documented-untested — `latestBodyMassLb() async -> Double?`** on the
  `HealthKitService` actor (conforming to `BodyMassReading`): runs an
  `HKSampleQuery` (or `HKStatisticsQuery` with `.mostRecent`) for `HKQuantityType(.bodyMass)`
  via `healthStore.execute(...)` inside a `withCheckedContinuation`, maps the returned
  `[HKQuantitySample]` to `(endDate, doubleValue(for: .gramUnit(with: .kilo)))` tuples,
  hands them to the pure converter, and returns the result. **Fail-open**: any thrown error,
  a `nil`/empty result, or a denied read all resolve to `nil` (never throws) — exactly the
  `BodyMassReading` contract and design.v5 §Failure modes. This boundary carries a doc
  comment noting it is intentionally untested (same convention as
  `fetchHydrationSamplesSince` / `startHydrationObserver`, which also wrap `execute`).

`HealthKitService` already conforms to one onboarding protocol via an empty extension; we
add `extension HealthKitService: BodyMassReading {}` once `latestBodyMassLb()` exists, with
no naming of `HealthKitService` in the Today layer.

### Provenance plumbing

`logWeighIn` gains a `source` parameter; `is_morning_weigh_in` is computed internally so the
30-min rule lives in exactly one place:

```swift
func logWeighIn(lb: Double, source: WeightLogSource) throws
```

- `source` is supplied by `CmdWeighIn` from its prefill-vs-pad branch: the "Good." CTA on
  the pre-filled hero confirms a HealthKit value (`.healthkit`); the pad's confirm yields a
  typed value (`.manualPad`). A small `enum WeightLogSource: String { case healthkit, manualPad = "manual_pad" }`
  keeps the design.v5 wire strings (`"healthkit"`, `"manual_pad"`) in one typed place and
  off the call sites. `WeightLogRow` is unchanged (its `source` stays `String`); the model
  maps `source.rawValue` into the row.
- `is_morning_weigh_in` is computed in the model as: `now` is within 30 minutes **after**
  the wake anchor, i.e. `wakeAnchor <= now && now <= wakeAnchor + 30*60`. The wake anchor is
  reconstructed from `facts.wakeTime` (DateComponents, hour+minute) spliced onto `now`'s
  y/m/d via the model's injected `calendar` — the same reconstruction `TodayCoordinator.resolve`
  already does (steps 1). The model reads `facts` via the existing `reader.todayFacts(now:)`
  seam. Per design.v5 the rule is "within 30 min of wake_time"; we implement it as the
  30-min window starting at the wake anchor (the weigh-in is part of the wake routine, and
  the coordinator only surfaces `.weighIn` at/after the wake anchor). The exact "30 min"
  bound is preserved verbatim and pinned by a boundary test (29:59 true, 30:01 false).

### CmdWeighIn loading state

`loadBodyMass` is async; between view-appear and the read completing, `prefilledWeightLb` is
`nil`, so the pad renders briefly and then flips to the hero once the value arrives. Per the
smallest-viable-change rule we accept the flip — no loading spinner. Rationale: design.v5
has no loading-state requirement for this surface, the read is a single local HealthKit
query (sub-second), and the flip is identical to the existing behavior the snapshot/UI tests
already exercise. This is a stated decision, not an omission.

### App wiring

`App.swift` injects `HealthKitService()` as the `bodyMass` seam in the release/normal path.
The `-ActSkipHealthKitAuthorization` UI-test path keeps `StubBodyMassReader()` so the read
stays deterministic (always `nil` → always pad), matching the existing UI-test assertion
that the weigh-in surface lands on the pad. This reuses the exact argument the file already
branches on for `healthAuthorizer`, so the two stay consistent.

## Files to touch / create

- `ios/Act/Today/BodyMassReading.swift` — add `enum WeightLogSource` (typed wire strings).
  Keep `StubBodyMassReader` (still used by the UI-test path). (edit)
- `ios/Act/Service/BodyMass.swift` — **new** small file: the pure
  `latestBodyMassLb(from:)` converter (module-internal `static` or free function) plus the
  kg→lb constant. SRP: weight-sample conversion, isolated from the actor and from HealthKit
  imports. (create)
- `ios/Act/Service/HealthKit.swift` — add the thin `latestBodyMassLb() async -> Double?`
  query wrapper on `HealthKitService` and `extension HealthKitService: BodyMassReading {}`.
  (edit)
- `ios/Act/Today/TodayCoordinatorModel.swift` — change `logWeighIn(lb:)` →
  `logWeighIn(lb:source:)`; compute `is_morning_weigh_in` from `facts.wakeTime` + `calendar`
  + `nowProvider`; map `source.rawValue` into the row; remove the FOLLOW-UP comment. (edit)
- `ios/Act/Today/Views/CmdWeighIn.swift` — `onGood` branches pass `.healthkit` from the
  pre-filled hero CTA and `.manualPad` from the pad confirm. Likely widen `onGood` to carry
  the source, or call the model with the branch's source at the binding site. (edit)
- `ios/Act/Today/Views/CmdWeighInScreen.swift` (or wherever the view binds to the model) —
  forward the source from the view callback into `logWeighIn(lb:source:)`. (edit, if a
  separate binding view exists)
- `ios/Act/App.swift` — inject `HealthKitService()` as `bodyMass` on the normal path; keep
  `StubBodyMassReader()` under `-ActSkipHealthKitAuthorization`. (edit)
- `ios/ActTests/Service/BodyMassTests.swift` — **new**: unit tests for the pure converter.
  (create)
- `ios/ActTests/Today/TodayCoordinatorModelTests.swift` — add provenance tests
  (`source` healthkit vs manual_pad; `is_morning_weigh_in` true/false + 30-min boundary).
  (edit)
- `ios/ActTests/Today/CmdWeighInTests.swift` (or the existing CmdWeighIn test file) — assert
  the prefill CTA reports `.healthkit` and the pad confirm reports `.manualPad`. (edit, if
  present)
- `ios/project.yml` — no change expected (new files land under existing globbed source
  groups); if globs are explicit, add the two new files and `xcodegen generate`. (verify)

## Sub-tasks (numbered; each one pair round, TDD-shaped, ordered)

1. **Pure body-mass converter (red→green).** Add `BodyMassTests` covering empty→nil,
   single kg→lb, most-recent-of-several (out-of-order input), and the kg→lb constant. Then
   add `ios/Act/Service/BodyMass.swift` with `latestBodyMassLb(from:)` to pass. No HealthKit
   import in this file. `swiftlint --strict`.

2. **HealthKitService read wrapper + BodyMassReading conformance.** Add the thin
   `latestBodyMassLb() async -> Double?` that runs the `HKSampleQuery`/`HKStatisticsQuery`,
   maps samples → tuples, delegates to the sub-task-1 converter, and fails open to `nil`;
   add `extension HealthKitService: BodyMassReading {}`. The query boundary is
   documented-untested (matching `fetchHydrationSamplesSince`); the converter it calls is
   already covered. No new behavior is added without a test — the only untested code is the
   thin un-fakeable `execute` wrapper, consistent with the existing observer/anchored-query
   wrappers. `swiftlint --strict`.

3. **WeightLogSource enum + provenance in the model (red→green).** Add `WeightLogSource`.
   Add `TodayCoordinatorModelTests`: (a) `logWeighIn(lb:source: .healthkit)` writes a row
   whose `source == "healthkit"`; (b) `.manualPad` writes `"manual_pad"`. Then change
   `logWeighIn(lb:)` → `logWeighIn(lb:source:)` and map `source.rawValue` into the row.
   `swiftlint --strict`.

4. **is_morning_weigh_in computation (red→green).** Add model tests with a pinned
   `nowProvider`, `calendar`, and a fake reader vending a known `wakeTime`: weigh-in 10 min
   after wake → `true`; weigh-in 90 min after wake → `false`; boundary at exactly 30:00
   (and 29:59 true / 30:01 false). Then compute the flag in `logWeighIn` from
   `facts.wakeTime` + `calendar` + `now` (reconstruct the wake anchor exactly as the
   resolver does) and write it into the row. `swiftlint --strict`.

5. **CmdWeighIn wires provenance through both branches.** Update/extend the CmdWeighIn view
   test so the pre-filled "Good." CTA reports `.healthkit` and the pad confirm reports
   `.manualPad`; then thread the source through `onGood` (or the binding view) into
   `logWeighIn(lb:source:)`. Keep the renderer pure (no model dependency in the view).
   `swiftlint --strict`.

6. **App wiring + UI-test guard.** Inject `HealthKitService()` as `bodyMass` on the normal
   path in `App.swift`; keep `StubBodyMassReader()` under `-ActSkipHealthKitAuthorization`.
   Run the existing weigh-in UI test (or the snapshot/manual-pad assertion) to confirm the
   skip path still lands on the pad and its assertion holds. If a snapshot reference is
   affected, follow the CI record path in CLAUDE.md (do not record locally unless the
   runtime matches CI). `swiftlint --strict` + full `xcodebuild test`.

## Out of scope

- Any other Cmd* screen (CmdPreWorkout, CmdMeal, CmdWalk, CmdEOD, etc.).
- The "STALE · TAP TO ENTER" last-cached-weight path (design.v5 §Failure modes "Smart scale
  offline at 05:00") — requires a cached-weight read the milestone hasn't built; current
  fail-open behavior (nil → manual pad) is the shipped, design-compliant degradation for the
  denied/no-data case.
- HealthKit read-authorization detection (impossible by Apple design; the service already
  documents this — absence of data is the de-facto denial signal).
- Notification wiring, CloudKit-mirror changes, `WeightLogRow` schema changes, GRDB
  migrations, `adherence_pct_cached` recompute changes.
- Changing the "30 min" rule or the wake-anchor semantics in design.v5.
- Drive-by refactors of the existing dedup/observer code.

## Open questions

1. **"within 30 min of wake_time" direction.** design.v5 says "within 30 min of wake_time";
   this plan implements it as the 30-min window *after* the wake anchor
   (`wakeAnchor <= now <= wakeAnchor + 30m`), since the coordinator only surfaces `.weighIn`
   at/after the wake anchor and the weigh-in is the first wake-routine action. If the intent
   was a symmetric ±30 min window around the anchor, sub-task 4's predicate and boundary
   tests change. Confirm the one-sided interpretation. (Resolver: user / design owner.)
2. **`onGood` signature vs binding-site mapping.** Two options to carry provenance from view
   to model: widen `CmdWeighIn.onGood` to `(Double, WeightLogSource) -> Void`, or keep
   `onGood: (Double) -> Void` and have the surrounding binding view choose the source by
   knowing which branch fired. Widening `onGood` is cleaner and keeps the source decision in
   the view that owns the branch; confirm acceptable since it touches the view's public
   closure signature (and any snapshot/preview call sites). (Resolver: reviewer preference.)
