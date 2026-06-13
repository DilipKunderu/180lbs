---
status: sketch
authored_by: architect (drift-check #1)
authored_at: 2026-05-22
scope: forward-steering for sub-task 4 (`onboarding`)
binds: docs/design/design.v4.md §Flow 4, §Stateful surfaces (Today coordinator), §Data model (PROFILE, WITHDRAWAL_STATE)
status_note: |
  This is a non-binding interface sketch surfaced for user approval. The
  onboarding driver MUST still follow Red→Green→Refactor: write the failing
  test, then the protocol stub, then the implementation. The shapes below
  exist so the driver does not have to re-derive constraints from design.v3
  during the test-first step.
---

# Onboarding interface sketch

## Why this exists

Sub-task 4 (`onboarding`) is the first sub-task that has to write to persistence (PROFILE + WITHDRAWAL_STATE), schedule local notifications, and request HealthKit / `UNUserNotificationCenter` authorization. The GRDB-backed local store doesn't land until todo #5 (schema). So onboarding has two viable shapes:

1. **UI-first**: ship the Onb* SwiftUI views and the `OnboardingCoordinator` against a `OnboardingRepository` protocol; the in-memory implementation is the only one that ships in sub-task 4. The GRDB-backed implementation lands in todo #5 behind the same protocol.
2. **Bundle schema into onboarding**: pull todo #5 forward and have onboarding land with the real GRDB store wired up.

The architect recommends **shape 1**. It keeps each sub-task small (SRP, smallest-viable-change), lets the snapshot harness exercise Onb* views immediately, and gives the schema todo a clear acceptance criterion ("swap the in-memory `OnboardingRepository` for a `GRDBOnboardingRepository`; all existing Onb* tests stay green"). The repository protocol below is the contract that bridges the two sub-tasks.

## Hard constraints inherited from design.v3

The onboarding driver MUST NOT relax any of these:

1. **`PROFILE` is a singleton.** The repository rejects a second `bootstrapProfile` call with a typed error. The app keys the PROFILE row on a fixed `CKRecord.ID` (e.g. `"profile-singleton"`); the local mirror keys it on a fixed primary key (e.g. `id = "profile-singleton"`).
2. **`profile.quit_date` is immutable post-onboarding.** Encode this at the type level: `ProfileDraft` carries `quit_date`; `ProfileMutation` does not.
3. **`profile.start_weight_lb` is immutable post-onboarding.** Same treatment as `quit_date`.
4. **`WITHDRAWAL_STATE` day-0 row is created atomically with the PROFILE row.** A `bootstrapProfile` that succeeded but left no withdrawal_state row would corrupt the cessation pillar invariant on first launch. The repository owns the atomicity contract; the implementation gets to choose how (single GRDB transaction is the obvious answer).
5. **The 7+7+1 local-notification batch and the CloudKit save are best-effort from onboarding's perspective.** Onboarding completes the moment the local PROFILE + WITHDRAWAL_STATE rows are written; notification registration and CloudKit sync happen async behind the door. A failure in either does NOT roll back the bootstrap (the user is now in the app; there is no going back). Notification permission denial follows the "Push." re-prompt path from §Failure modes.
6. **Hero-word-per-screen + single-CTA hard line applies to every Onb* view.** The Settings + Rotation editor exemption does NOT extend to onboarding. `OnbWelcome` / `OnbQuit` / `OnbRotation` / `OnbWeight` / `OnbSchedule` / `OnbHealthKit` / `OnbNotifications` / `OnbBottle` / `OnbScale` / `OnbConfirm` each carry one hero word ending in a period (`Welcome.`, `Quit.`, `Rotate.`, `Weigh.`, `Schedule.`, `Health.`, `Push.`, `Bottle.`, `Scale.`, `Begin.` are reasonable; final wording is the user's call).
7. **No cessation shame language anywhere in Onb* copy.** Per §Hard lines: allowed register is "Honest." / "No shame. Just data." / "Tomorrow is easier." / "Today is the worst day." Banned register includes "you got this", "stay strong", "be brave", "slip", "moment of weakness". The `OnbQuit` CTA wording "I am a non-smoker." in Flow 4 is the canonical example of the allowed register.
8. **The 21:00 EOD forced-choice CTA is the *only* forced-choice in the app** (§Hard lines). Every Onb* screen has a sticky lime CTA that is always enabled; "Back" is a mono text link above the sticky CTA, never a secondary button.

## Sketch — types and protocol

> **SUPERSEDED — shipped types differ from this sketch.**
> The `OnboardingStep` enum and store protocol below have been updated to match
> the shipped code. The remaining type sketches (`ProfileDraft`, `ProfileMutation`,
> `Profile`, `CessationTrigger`) are stale: the shipped types use `String`/`Double`
> (not `Decimal`/`DateComponents`) and differ in field names and structure.
> **Do not implement from the stale sketches.** Use the shipped source files as
> the authoritative source of truth:
> - `ios/Act/Onboarding/` — `OnboardingStep`, `OnboardingFlowModel`, `OnboardingProfileStore`
> - `ios/Act/Persistence/PersistenceSupport.swift` — `ProfileDraft`, `Profile`, `LocalStoreError`

The store protocol is the surface that bridges the Onb* views and persistence. Errors surface via the existing `LocalStoreError` type (e.g. `profileAlreadyBootstrapped`), not a bespoke `OnboardingError`.

```swift
// ios/Act/Onboarding/OnboardingStep.swift  (SHIPPED)

/// Linear progression through the onboarding flow.
enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case profile
    case health
    case notifications
    case scale
    case hydration
    case quit
    case rotation
    case grocery
}
```

```swift
// ios/Act/Onboarding/OnboardingProfileStore.swift  (SHIPPED)

/// Store surface — the boundary between Onb* views and persistence.
///
/// Errors surface as `LocalStoreError` (e.g. `profileAlreadyBootstrapped`),
/// not a bespoke OnboardingError. Both methods are synchronous (not async);
/// callers that need main-actor isolation manage that at the call site.
///
/// Note: this protocol is intentionally narrow. It does NOT cover
/// notification registration, HealthKit authorization, or CloudKit sync —
/// those are separate single-responsibility services injected into the
/// coordinator alongside the store.
protocol OnboardingProfileStore: AnyObject {
    /// Returns nil iff `bootstrapProfile` has never succeeded.
    func currentProfile() throws -> Profile?

    /// Atomically inserts the singleton PROFILE row + WITHDRAWAL_STATE day-0 row.
    /// Throws `LocalStoreError.profileAlreadyBootstrapped` on a second call.
    /// Returns the fully-hydrated Profile so the caller does not need to re-read.
    func bootstrapProfile(_ draft: ProfileDraft) throws -> Profile
}
```

> **Removed sketch types — do not implement from them.**
>
> The original sketch also defined `ProfileDraft` (with `Decimal`/`DateComponents`),
> `ProfileMutation`, `Profile`, `CessationTrigger`, and `OnboardingError`. Those
> blocks have been removed here because they were superseded by the shipped types in
> `PersistenceSupport.swift` and the Onboarding layer. See the source files listed at
> the top of this section for the authoritative shapes.

## Sketch — top-level router

The very first thing the app does on launch is decide: is this a returning user (PROFILE exists → land in `TodayCoordinator`) or a fresh install (no PROFILE → land in `OnboardingCoordinator`). This is a single boundary that lives at the root of the view hierarchy.

```swift
// ios/Act/RootView.swift  (sketch — driver writes the real file in sub-task 4)

import SwiftUI

struct RootView: View {
    @State private var profile: Profile?
    @State private var didLoadInitial = false
    let repository: any OnboardingRepository

    var body: some View {
        ZStack {
            if !didLoadInitial {
                // Initial load: black background only. No spinner — the design
                // does not own a loading spinner pattern yet. Local SQLite reads
                // typically resolve in <50ms; on cold launch the app launch
                // screen covers the gap.
                Color.black.ignoresSafeArea()
            } else if profile == nil {
                OnboardingCoordinator(
                    repository: repository,
                    onComplete: { profile = $0 }
                )
            } else {
                TodayCoordinator(/* injected once it exists */)
            }
        }
        .task {
            profile = try? await repository.currentProfile()
            didLoadInitial = true
        }
    }
}
```

Tests for `RootView` are pure-coordinator tests against an in-memory `OnboardingRepository`: cold-launch → onboarding visible; bootstrap → Today visible; resume (PROFILE exists at launch) → Today visible directly.

## Sketch — snapshot harness conventions for Onb*

Each Onb* view is one snapshot test under `ios/ActTests/Snapshots/Onb<Name>SnapshotTests.swift`. References live in `ios/ActTests/__snapshots__/` (already established by `test-scaffold`). The bootstrap-skip helper (`XCTBootstrapSkipIfReferenceMissing`) is OFF-LIMITS for Onb* tests — the contract is: commit the reference PNG in the same PR. The placeholder `ContentViewSnapshotTests` should be deleted in sub-task 4 once the first Onb* snapshot lands with its real reference.

A two-state minimum per Onb* view: empty / valid. `OnbQuit` adds a third: with-triggers-selected. `OnbHealthKit` and `OnbNotifications` add a denied-state variant.

## What sub-task 4 should NOT do

- Land the GRDB-backed repository. Schema is todo #5; let it stay there.
- Register the 7+7+1 local notifications. That requires the notification-scheduling service which is its own sub-task. Onboarding produces the `ProfileDraft` and persists it; the scheduling service reads PROFILE and writes to `UNUserNotificationCenter` in a later sub-task. (See "Open cross-cutting concern: BG identifier" in the drift-check report.)
- Save to CloudKit. CloudKit sync is wired in a later sub-task; the repository protocol above contains no CloudKit reference. The local mirror is the source of truth on day 1.
- Add `import FoundationModels` anywhere. The framework is install-gated via `OTHER_LDFLAGS[sdk=iphoneos*]` per `scaffold-ios`; the first code-level usage lands with the weekly-insight sub-task. Onboarding has no AI surface.

## Open question for the driver

`OnbBottle` and `OnbScale` are listed as auxiliary steps in this sketch (between notifications and confirm). The design does not explicitly enumerate Onb* steps in v3; the list above is the architect's best reading of Flow 4 + Integrations + §Behavior and schedule. If the driver disagrees with the step list, raise it before writing the first failing test — the step list cascades into the entire navigation graph and a swap mid-implementation is expensive. Acceptable resolutions include (a) collapsing bottle + scale into a single `OnbHardware.` step, or (b) deferring both to a "Hardware" entry inside `CmdSettings` post-onboarding.
