# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Act." — a single-user iOS coach app (dark-mode only, Apple-native, TestFlight-only). All app code lives under `ios/`; product/design truth lives in `docs/design/design.v3.md`.

## Commands

The Xcode project is **generated** — `ios/Act.xcodeproj` is gitignored. Regenerate after any `ios/project.yml` change:

```bash
cd ios && xcodegen generate
```

Run all tests (CI uses iPhone 17 Pro on iOS 26.5; the project always targets the latest iOS):

```bash
cd ios
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

Run a single test class or method: add `-only-testing:ActTests/OnboardingFlowModelTests` (or `.../OnboardingFlowModelTests/testName`) to the command above.

Lint (CI runs `--strict`, so warnings fail the build):

```bash
swiftlint lint --strict ios/
```

Design-doc invariants check (also a CI job):

```bash
bash scripts/check-design-docs.sh
```

Optional fast pre-push lint gate: `git config core.hooksPath .githooks`.

### Snapshot tests

Snapshot tests compare SwiftUI renders against committed PNGs in `ios/ActTests/__snapshots__/`. CI sets `SNAPSHOT_TESTING_RECORD=never` (passed as `TEST_RUNNER_SNAPSHOT_TESTING_RECORD` — xcodebuild only forwards `TEST_RUNNER_`-prefixed env vars into the simulator test process, stripping the prefix), so a missing reference is a hard failure. References must be recorded on CI's renderer (Xcode 26.5 / iOS 26.5): prefer the CI record path — run the **CI** workflow manually with `record_snapshots=true`, download the `snapshots-<run_id>` artifact, commit the PNGs. Only record locally (`TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test ...` without the old CODE_SIGNING flags — a bare `SNAPSHOT_TESTING_RECORD` never reaches the test process) if your simulator runtime matches CI's, otherwise font/metric drift causes perpetual diffs. New snapshot tests inherit from `SnapshotTestCase` (`ios/ActTests/Support/SnapshotTestCase.swift`); references render at `ViewImageConfig.iPhone13Pro` dimensions.

## Architecture

### Targets (XcodeGen spec: `ios/project.yml`)

Four targets: `Act` (app, `com.act.coach`), `ActWidgets` and `ActLiveActivity` (extensions), `ActTests` (unit tests, links the app target). The three runtime targets share App Group `group.com.act.coach`, which holds the shared SQLite file. FoundationModels (Apple Intelligence) is linked **only for device SDK builds** via a conditional `OTHER_LDFLAGS[sdk=iphoneos*]` — the framework doesn't exist in the simulator SDK; don't "simplify" this into an unconditional link, and don't move HealthKit linking into that flag (the conditional value *replaces* the base, it doesn't merge).

### Persistence (local-first, `ios/Act/Persistence/`)

Dual representation of all 15 user-domain entities, defined by `design.v3.md §Data model`:

- `CKRecords/*CKRecord.swift` — CloudKit record encode/decode per entity.
- `Rows/*Row.swift` — GRDB row types for the local SQLite mirror.
- `LocalStore` — the single write path. Public write APIs commit the GRDB transaction **first**, then propagate `CloudDelta`s (CKRecord saves/deletes) to CloudKit best-effort; a CloudKit failure never rolls back the local row. Never put cloud calls inside the GRDB write block.
- The SQLite file lives in the App Group container (`act.sqlite`), opened with WAL + 5s busy timeout so app/widget/Live Activity processes can share it.
- Schema changes go through `LocalStoreMigrations.swift` (GRDB `DatabaseMigrator`).
- Client-side invariants are enforced in `LocalStore` and surfaced as typed `LocalStoreError`s (e.g. `PROFILE` is a singleton row; `bootstrapProfile(_:)` atomically inserts PROFILE + day-0 WITHDRAWAL_STATE in one transaction and throws on a second call).

Tests use `MockCKDatabase` (`ios/ActTests/Support/`) — an in-memory `CloudDatabase` shim; no real CloudKit in CI.

### Onboarding (`ios/Act/Onboarding/`)

Renderer-free core (no SwiftUI in these types): `OnboardingStep` (linear step enum), `OnboardingFlowModel` (progression), `ProfileDraftBuilder` (accumulates answers into a `ProfileDraft`), `RootDestination.resolve(profile:readFailed:)` (loading/onboarding/today routing). The interface contract — including which profile fields are immutable post-onboarding (`quit_date`, `start_weight_lb` live only on the draft, never on a mutation type) — is in `docs/architecture/onboarding-interface.md`.

### HealthKit (`ios/Act/Service/HealthKit.swift`)

`HealthKitService` is the **only** production path that touches `HKHealthStore`. Hydration streams via observer + anchored query; manual entries within 60s of a same-volume Hidrate sample are de-duped per `design.v3.md §Failure modes`.

## Design docs are immutable

`docs/design/design.v*.md` files may never be modified, deleted, or renamed once merged — CI's `design-doc-check` job fails the build on any `M`/`D`/`R` diff. To change the design, add a new `design.v(N+1).md` (with the required frontmatter keys: `version`, `supersedes`, `created_at`, `created_by`, non-empty `changelog_vs_previous`) and bump `docs/design/CURRENT`. The current canonical doc is whatever `CURRENT` points to (`design.v3.md` today).

## Design system constraints (enforced)

A custom SwiftLint rule bans hex colors outside the locked background set (`#000000`, `#0A0A0A`, `#141414`, `#1C1C1E`; `#FFFFFF` for legibility tests only) — all other colors come from `ACTTokens` (`ios/Act/Design/ACTTokens.swift`, oklch-based; invariants tested in `ACTTokensTests`). UI follows the "A · Command" system: one hero word per screen ending in a period, single lime sticky CTA, SF Mono for all numerics, no cards. Cessation copy has a locked register — no shame language ("stay strong", "slip", etc.); see `docs/architecture/onboarding-interface.md` §7 and `design.v3.md §Hard lines`.

## CI / deploy

`.github/workflows/ci.yml` runs `design-doc-check`, `swift-lint` (strict), and `xcode-test` on every push/PR. Deploy to TestFlight is tag-triggered (`.github/workflows/deploy.yml` → Fastlane `:beta` lane).
