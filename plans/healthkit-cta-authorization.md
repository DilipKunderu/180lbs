# HealthKit authorization on the onboarding "Health." CTA

Created 2026-06-12 by the pair-programming workflow (architect: fable, AUTHOR_PLAN; judged approve by principal: opus, 1 warn / 4 info).

Source of truth: docs/design/design.v3.md (v3)

## Overview

`OnbHealthView`'s "Allow" CTA currently just calls `model.advance()`. Inject a narrow, renderer-free authorization seam (`HealthAuthorizationRequesting`) into `OnboardingCoordinatorModel` so that advancing off `.health` fires a best-effort HealthKit read/write authorization request via the existing `HealthKitService` actor (the only sanctioned `HKHealthStore` path), while the flow advances immediately and unconditionally. Per design.v3 §Failure modes and onboarding-interface.md constraint #5, denial and errors are swallowed with no UI. The UI walkthrough stays deterministic via a `-ActSkipHealthKitAuthorization` launch argument (no-op authorizer), mirroring `-ActResetLocalStore` — the real system Health sheet is never presented in CI.

## Architecture

- Port owned by the consumer: `protocol HealthAuthorizationRequesting: Sendable { func requestAuthorization() async throws }` in `ios/Act/Onboarding/HealthAuthorizationRequesting.swift` (no HealthKit import in the onboarding layer).
- Adapter: `extension HealthKitService: HealthAuthorizationRequesting {}` (existing `requestAuthorization() async throws` matches verbatim; actor → implicitly Sendable; denial completes without throwing, already pinned by `test_requestAuthorization_completes_evenWhenStoreCallsBackWithFalse`).
- Side-effect in `OnboardingCoordinatorModel.advance()`: when leaving `.health`, advance synchronously first, then `Task { try? await healthAuthorizer.requestAuthorization() }`; retain as `@ObservationIgnored private(set) var healthAuthorizationTask: Task<Void, Never>?` so tests await it deterministically. Document that the handle reflects only the most recent leave-`.health` request (re-entry overwrites; iOS no-ops repeat sheets).
- Composition root: `RootModel` passes the authorizer through to its `OnboardingCoordinatorModel`; `App.swift` picks `HealthKitService()` normally or a `#if DEBUG` `NoOpHealthAuthorizer` under `-ActSkipHealthKitAuthorization`.
- **Judge revision (applied)**: do not make `healthAuthorizer` a required param on `RootModel.init` — default it so the 6 existing `RootModel(store:)` call sites stay untouched and the single new spy-injecting test is the only red signal. (Preserve layering: default to nil/no-op in the onboarding layer rather than referencing `HealthKitService` from `RootModel`; `App.swift` injects the real one.)
- No view changes; no snapshot reference changes. Entitlement + `NSHealth*UsageDescription` strings already present.

## Sub-tasks

1. **`health-auth-seam`** — protocol + coordinator side-effect (renderer-free).
   - Red: `SpyHealthAuthorizer` (lock-guarded `@unchecked Sendable`, call count + configurable error); tests: advance from `.health` advances synchronously to `.notifications` and requests exactly once (await the task handle); throwing authorizer still advances; other steps never request (count 0, handle nil).
   - Green: protocol file; coordinator gains authorizer injection + `.health` branch + retained handle.
2. **`health-auth-wiring`** — adapter, composition root, deterministic UI test.
   - Red: `RootModelTests.test_onboardingModel_requestsHealthAuthorization_throughInjectedAuthorizer`.
   - Green: `HealthKitService` conformance; `RootModel` pass-through (defaulted); `App.swift` composition; `OnboardingFlowUITests` adds the launch argument.
   - Verify: full suite incl. UI walkthrough; `swiftlint lint --strict ios/`; `xcodegen generate` after new files.

## Open questions

1. Sheet placement (cosmetic): advance-then-request means the real sheet appears over "Push."; could fire before advance with zero architectural difference. Default: advance-then-request.
2. Re-entry fires a second request; iOS no-ops repeat sheets; no guard.
3. Denied-state snapshot variant deferred until degraded-mode copy exists.

## Judge findings (principal, opus)

- warn/scope: required `healthAuthorizer` on RootModel.init inflates diff across 6 unrelated tests → default it (applied above).
- info: step order, actor Sendability, view prop surface, and red→green feasibility all verified against the repo.
- info/risk: `(false, error)` callback throws but `try?` swallows per failure-mode contract; task handle correctly `@ObservationIgnored`.
