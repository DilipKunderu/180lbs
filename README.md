# Act.

Single-user iOS coach — dark-mode only, Apple-native stack, TestFlight-only.

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 26.x (CI builds on 26.5) |
| iOS deployment target | 26.0 — always tracks the latest iOS |
| Device | A17 Pro or M-series (Apple Intelligence requirement) |
| Ruby | 3.x (for Fastlane) |
| XcodeGen | 2.x (`brew install xcodegen`) |

## Developer setup

```bash
# 1. Clone
git clone https://github.com/dilipkunderu/180lbs.git && cd 180lbs

# 2. Install XcodeGen (one-time)
brew install xcodegen

# 3. Generate the Xcode project (run again after any project.yml change)
cd ios && xcodegen generate && cd ..

# 4. Open in Xcode
open ios/Act.xcodeproj
```

> **Note:** `ios/Act.xcodeproj` is generated from `ios/project.yml` and is gitignored.
> Always run `xcodegen generate` after pulling changes that touch `ios/project.yml`.

## Project structure

```
ios/
├── project.yml              # XcodeGen spec (source of truth for the Xcode project)
├── Act/                     # App target  (bundle ID: com.act.coach)
│   ├── App.swift            # LocalStore → RootModel → RootView
│   ├── RootView.swift       # loading / onboarding / Today routing
│   ├── Info.plist
│   ├── Act.entitlements
│   ├── Design/
│   │   └── ACTTokens.swift  # oklch-derived color + type tokens
│   ├── Onboarding/
│   │   ├── ...              # renderer-free core (flow model, draft builder, coordinator/root models)
│   │   └── Views/           # OnbShell + the 9 Onb* step views (design JSX is the source of truth)
│   └── Today/
│       ├── ...              # renderer-free core: TodayState, TodayCoordinator (pure resolver),
│       │                    #   TodayFacts(+Reading), WeightLogWriting, BodyMassReading, model
│       └── Views/           # TodayCoordinatorView switch + CmdWeighIn / CmdWeightPad (other Cmd* screens TBD)
├── ActWidgets/              # WidgetKit extension  (com.act.coach.Widgets)
│   ├── ActWidgetsBundle.swift
│   ├── Info.plist
│   └── ActWidgets.entitlements
├── ActLiveActivity/         # Live Activity extension  (com.act.coach.LiveActivity)
│   ├── ActLiveActivityBundle.swift
│   ├── Info.plist
│   └── ActLiveActivity.entitlements
└── ActTests/                # Unit-test target  (com.act.coach.Tests)
    ├── ACTTokensTests.swift     # design-token invariants (incl. accent Display-P3 values)
    ├── __snapshots__/           # committed reference PNGs (regenerate via the CI record path; see Snapshot tests below)
    ├── Coordinators/            # TodayCoordinator + model tests (HydrationMonitor / CessationCoordinator TBD)
    ├── Persistence/             # MockCKDatabase harness + invariant tests
    │   └── MockCKDatabaseTests.swift
    ├── Snapshots/               # SwiftUI snapshot tests (one file per Onb* view; references committed in the same PR)
    └── Support/                 # shared test helpers
        ├── MockCKDatabase.swift # in-memory CKDatabase shim (CI-safe, no real CloudKit)
        └── SnapshotTestCase.swift  # XCTestCase base class for snapshot tests
```

### Target bundle IDs

| Target | Bundle ID |
|--------|-----------|
| App | `com.act.coach` |
| WidgetKit extension | `com.act.coach.Widgets` |
| Live Activity extension | `com.act.coach.LiveActivity` |
| Test bundle | `com.act.coach.Tests` |

The three runtime targets (app + both extensions) are enrolled in App Group `group.com.act.coach` (shared GRDB/SQLite container). The `ActTests` bundle is not in the App Group — it links the app target for in-process unit testing and has no need for the shared container.

## Capabilities wired (app target)

| Capability | Notes |
|-----------|-------|
| HealthKit (read + write) | Usage strings in Info.plist |
| CloudKit (`iCloud.com.act.coach`) | Private database for cross-device sync/backup |
| App Groups (`group.com.act.coach`) | Shared SQLite mirror for extensions |
| Push Notifications (entitlement only) | Required by ActivityKit; no APNs key exists. Local-notification *permission* is requested at the `OnbNotifications` step via `NotificationService`; scheduled-notification registration is deferred to a future subsystem |
| Background Fetch + Processing | `BGProcessingTask` id: `com.act.coach.weekly-insight` |
| Live Activities (`NSSupportsLiveActivities`) | ActivityKit via Live Activity extension |

## HealthKit integration

`HealthKitService` is the only production path that touches `HKHealthStore`, requesting read access for body mass, step count, sleep analysis, resting heart rate, heart rate variability (SDNN), VO2 max, and dietary water, plus write access for workouts, dietary energy consumed, and dietary water. Hydration updates stream through an observer + anchored query pair, and de-dup follows the binding contract in `docs/design/design.v5.md` §Failure modes: manual tap entries within 60 seconds of a same-volume Hidrate sample are treated as the same sip when computing daily running totals.

## Persistence layer

Act. uses a local-first persistence split defined by `docs/design/design.v5.md` §Data model: all 15 user-domain entities are represented as CloudKit `CKRecord` types, and the app reads/writes through a GRDB SQLite mirror for fast on-device queries and offline-first writes. The SQLite file is shared across the app, WidgetKit extension, and Live Activity extension via the App Group container path `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.act.coach")!.appendingPathComponent("act.sqlite")`, so every runtime surface sees the same data without cross-sandbox read failures.

`LocalStore` opens the production SQLite via `DatabasePool` configured with `busyMode = .timeout(5.0)` and `PRAGMA journal_mode = WAL`, so the main app, widget, and Live Activity processes can all read/write the same file without contention failures. Public write APIs commit the GRDB transaction first, then propagate `CKRecord` deltas to CloudKit best-effort; a CloudKit failure does not roll back the local row, preserving the offline-first contract from `design.v5 §Data model`. Onboarding goes through `bootstrapProfile(_:)`, which atomically inserts the singleton `PROFILE` row and the day-0 `WITHDRAWAL_STATE` sentinel row in a single transaction and throws `LocalStoreError.profileAlreadyBootstrapped` on a second call. The cached `PROFILE` columns are refreshed before each commit per `design.v5 §Data model`: `current_weight_lb_cached` on weight writes, `clean_streak_days` and the 7-day rolling `adherence_pct_cached` on the relevant writes — each write propagates a single refreshed `PROFILE` delta. `quit_date` and `start_weight_lb` are immutable post-onboarding; the write path rejects changes with `LocalStoreError.profileImmutableFieldChanged`.

## Running tests locally

```bash
cd ios
xcodegen generate
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

### Snapshot tests — recording reference images

Snapshot tests compare rendered SwiftUI views against committed PNGs in
`ios/ActTests/__snapshots__/`. CI sets `SNAPSHOT_TESTING_RECORD=never` (via
`TEST_RUNNER_SNAPSHOT_TESTING_RECORD` — xcodebuild only forwards env vars into
the simulator test process when they carry the `TEST_RUNNER_` prefix, which it
strips) so a missing reference is a hard failure.

References must match the renderer that verifies them. CI verifies on
**Xcode 26.5 / iOS 26.5**; recording on a different local toolchain (e.g.
Xcode 26 / iOS 26) can yield font/metric drift and perpetual CI diffs. Prefer
recording on CI's renderer via the **CI record path** below; use the local
workflow only when your local simulator runtime matches CI.

**CI record path (recommended — matches CI's renderer exactly):**

1. Push your feature branch (with the new snapshot test added).
2. Actions tab → **CI** workflow → **Run workflow** → set `record_snapshots = true`
   on your branch. The run records references on CI's iOS 26.5 simulator and is
   allowed to "fail" the snapshot assertions.
3. Download the `snapshots-<run_id>` artifact, copy the PNGs into
   `ios/ActTests/__snapshots__/`, commit, and push. The next normal run verifies
   them green.

**Local record path (only if your local sim runtime matches CI):**

```bash
cd ios
xcodegen generate
# TEST_RUNNER_ prefix required: xcodebuild strips it and forwards the variable
# into the test process; a bare SNAPSHOT_TESTING_RECORD=all never reaches it.
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
# tests will "fail" with "Record mode is on" — that is expected
git add ios/ActTests/__snapshots__/
git commit -m "chore(snapshots): record reference PNGs for <feature>"
# run tests again without the env var to confirm they pass
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

> **Device consistency:** Reference PNGs render at `ViewImageConfig.iPhone13Pro`
> layout dimensions (deterministic across simulators), but always pass the
> same `-destination` simulator that CI uses (`iPhone 17 Pro`, iOS 26.5) so
> that font hinting and text layout match CI byte-for-byte.

## TestFlight / CI/CD

- **CI**: GitHub Actions (`.github/workflows/ci.yml`) — `design-doc-check`, `swift-lint`, `xcode-test` run on every branch push (and on fork PRs; same-repo PRs reuse the push run's checks, attached by head SHA). SwiftLint is version-pinned (`SWIFTLINT_VERSION` in `ci.yml`) on Ubuntu; Swift packages are cached via `ios/SourcePackages`.
- **Deploy**: `.github/workflows/deploy.yml` — triggered on version tag push, uploads to TestFlight via Fastlane `:beta` lane (requires `APP_STORE_CONNECT_API_KEY_*` secrets).

## Design

See `docs/design/design.v5.md` (current canonical design — the file named in `docs/design/CURRENT`). Design files are immutable once merged; each new version supersedes the last.
