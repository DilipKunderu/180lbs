# Onboarding 9.1b — Renderer Layer

Created 2026-06-12 from an AI planning session. Follows `plans/ci-orchestration-optimization.md` (merged as PR #12), which fixed the snapshot record path this phase depends on.

## Goal

Ship the SwiftUI rendering layer for onboarding on branch `feat/onboarding-9.1b`: the 9 step views from the design JSX, a coordinator that drives 9.1a's renderer-free core, root routing, and app wiring — with snapshot references committed in the same PR per the harness contract.

## Context

- 9.1a (PR #10) shipped the renderer-free core: `OnboardingStep` (9 steps pinned to JSX order: welcome, profile, health, notifications, scale, hydration, quit, rotation, grocery), `OnboardingFlowModel`, `ProfileDraftBuilder`, `RootDestination`, `OnboardingProfileStore` (implemented by `LocalStore` — schema landed *before* onboarding, flipping the order assumed by `docs/architecture/onboarding-interface.md`, so no in-memory repository is needed; the sketch's repository/async shapes are superseded by 9.1a's sync `OnboardingProfileStore`).
- Design source of truth: `design/180LB_extracted/components/variation-a-onboarding.jsx` (`OnbShell` skeleton + 9 screens, hero words: Act. / You. / Health. / Push. / Weigh. / Sip. / Quit. / Eat. / Shop.). Copy register is locked (no shame language); the JSX copy is canonical.
- Constraints from `onboarding-interface.md` that still bind: hero-word + single always-enabled lime CTA per screen; "Back" is a mono text link above the CTA, never a button; no notification registration / CloudKit / FoundationModels in this sub-task; delete the `ContentViewSnapshotTests` bootstrap sample once the first real Onb* snapshot lands.

## Design decisions

1. **`OnboardingFlowModel` gains `@Observable`** (`import Observation` — still renderer-free; Observation ≠ SwiftUI). Minimal change to a 9.1a type so SwiftUI invalidates on `step`/draft changes.
2. **`OnboardingCoordinatorModel`** (new, renderer-free, `@Observable`): composes `OnboardingFlowModel` + `OnboardingProfileStore`. Owns: advance/back passthrough, stamping `draftBuilder.quitDate` (yyyy-MM-dd, injected `nowProvider`/timezone) when advancing past `.quit`, and on flow completion calling `bootstrapProfile(draftBuilder.build())` → `onFinished(Profile)`; a bootstrap throw sets `bootstrapFailed` (no rollback UX in this sub-task — CTA stays enabled for retry).
3. **`RootModel`** (new, renderer-free, `@Observable`): wraps `RootDestination.resolve`; `load()` reads `currentProfile()` (throw → `readFailed: true` → `.loading` black screen, 9.1a semantics); `onboardingFinished` → `.today`. Accepts `OnboardingProfileStore?` so a failed `LocalStore()` at app launch degrades to `.loading`.
4. **Views are dumb**: step views take plain values/closures (`Binding` only where TextField demands it), so snapshot tests construct them with literals. Interactivity lives only in `OnbQuit` (trigger chips → snake_case raw values per the interface sketch: social_invite, stress, boredom, ritual, specific_person, specific_place; why-sentence TextField).
5. **`.today` routes to `ContentView`** (existing placeholder) until the Today coordinator sub-task lands.

## Files

New, under `ios/Act/Onboarding/`:
- `OnboardingCoordinatorModel.swift`, `RootModel.swift` (renderer-free)
- `Views/OnbShell.swift` (hero / sub / content / secondary / back link / sticky 56pt lime CTA, all colors via `ACTTokens`)
- `Views/OnbPrimitives.swift` (`OnbRow` key/value row with hairline divider, `OnbSectionLabel` mono uppercase label)
- `Views/Onb{Welcome,Profile,Health,Notifications,Scale,Hydration,Quit,Rotation,Grocery}View.swift` (one per JSX screen)
- `Views/OnboardingCoordinatorView.swift` (switch on step → view, wires CTA/back/bindings)
- `ios/Act/RootView.swift` (loading → black / onboarding → coordinator / today → ContentView)

Modified: `OnboardingFlowModel.swift` (+`@Observable`), `ios/Act/App.swift` (LocalStore → RootModel → RootView).

Deleted per harness contract: `ContentViewSnapshotTests.swift`, its reference PNG, `XCTBootstrapSkipIfReferenceMissing` + `SnapshotBootstrapSkipTests.swift` (helper exists only for the bootstrap path, which ends here).

Tests:
- `ios/ActTests/Onboarding/OnboardingCoordinatorModelTests.swift` — advance/back passthrough, quit-date stamping (injected clock), completion → bootstrap → onFinished, bootstrap failure path (fake store).
- `ios/ActTests/Onboarding/RootModelTests.swift` — nil profile → onboarding, profile → today, store throws → loading, nil store → loading, onboardingFinished → today.
- `ios/ActTests/Snapshots/Onb*SnapshotTests.swift` — one per view; `OnbQuit` gets two states (empty, triggers-selected + why filled). References recorded via the CI record path.

## TDD note

No local test execution is possible (local Xcode 26.5 lacks the iOS 26.5 platform download and has no 18.1 runtime) — red/green runs happen on CI, same as the rest of this repo's history. Tests are written before/with each unit and pushed together; CI is the arbiter.

## Verification / landing sequence

1. Push branch (snapshot tests fail: missing references — expected hard red; this is the documented minting flow).
2. Dispatch **CI** with `record_snapshots=true` (cancels the red push run via shared concurrency group), download `snapshots-<run_id>` artifact, inspect PNGs against the JSX, commit.
3. Next push must be fully green with every Onb* snapshot **executing** (no skips remain — the helper is deleted).
4. Open PR referencing this plan; README architecture section updated in the same PR.
