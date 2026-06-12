# Act.

Single-user iOS coach — dark-mode only, Apple-native stack, TestFlight-only.

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16.2+ |
| iOS deployment target | 18.1 (hard floor) |
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
│   ├── App.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   ├── Act.entitlements
│   └── Design/
│       └── ACTTokens.swift  # Reserved for design-tokens todo
├── ActWidgets/              # WidgetKit extension  (com.act.coach.Widgets)
│   ├── ActWidgetsBundle.swift
│   ├── Info.plist
│   └── ActWidgets.entitlements
├── ActLiveActivity/         # Live Activity extension  (com.act.coach.LiveActivity)
│   ├── ActLiveActivityBundle.swift
│   ├── Info.plist
│   └── ActLiveActivity.entitlements
└── ActTests/                # Unit-test target  (com.act.coach.Tests)
    ├── ActTests.swift           # scaffold smoke test
    ├── ACTTokensTests.swift     # design-token invariants
    ├── __snapshots__/           # committed reference PNGs (regenerate with SNAPSHOT_TESTING_RECORD=all)
    ├── Coordinators/            # TodayCoordinator / HydrationMonitor / CessationCoordinator tests (future)
    ├── Persistence/             # MockCKDatabase harness + invariant tests
    │   └── MockCKDatabaseTests.swift
    ├── Snapshots/               # SwiftUI snapshot tests (one per feature view, added per todo)
    │   └── ContentViewSnapshotTests.swift
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
| Push Notifications (entitlement only) | Required by ActivityKit; no APNs key exists |
| Background Fetch + Processing | `BGProcessingTask` id: `com.act.coach.weekly-insight` |
| Live Activities (`NSSupportsLiveActivities`) | ActivityKit via Live Activity extension |

## HealthKit integration

`HealthKitService` is the only production path that touches `HKHealthStore`, requesting read access for body mass, step count, sleep analysis, resting heart rate, heart rate variability (SDNN), VO2 max, and dietary water, plus write access for workouts, dietary energy consumed, and dietary water. Hydration updates stream through an observer + anchored query pair, and de-dup follows the binding contract in `docs/design/design.v3.md` §Failure modes: manual tap entries within 60 seconds of a same-volume Hidrate sample are treated as the same sip when computing daily running totals.

## Persistence layer

Act. uses a local-first persistence split defined by `docs/design/design.v3.md` §Data model: all 15 user-domain entities are represented as CloudKit `CKRecord` types, and the app reads/writes through a GRDB SQLite mirror for fast on-device queries and offline-first writes. The SQLite file is shared across the app, WidgetKit extension, and Live Activity extension via the App Group container path `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.act.coach")!.appendingPathComponent("act.sqlite")`, so every runtime surface sees the same data without cross-sandbox read failures.

`LocalStore` opens the production SQLite via `DatabasePool` configured with `busyMode = .timeout(5.0)` and `PRAGMA journal_mode = WAL`, so the main app, widget, and Live Activity processes can all read/write the same file without contention failures. Public write APIs commit the GRDB transaction first, then propagate `CKRecord` deltas to CloudKit best-effort; a CloudKit failure does not roll back the local row, preserving the offline-first contract from `design.v3 §Data model:160`. Onboarding goes through `bootstrapProfile(_:)`, which atomically inserts the singleton `PROFILE` row and the day-0 `WITHDRAWAL_STATE` row in a single transaction and throws `LocalStoreError.profileAlreadyBootstrapped` on a second call.

## Running tests locally

```bash
cd ios
xcodegen generate
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

### Snapshot tests — recording reference images

Snapshot tests compare rendered SwiftUI views against committed PNGs in
`ios/ActTests/__snapshots__/`. CI sets `SNAPSHOT_TESTING_RECORD=never` (via
`TEST_RUNNER_SNAPSHOT_TESTING_RECORD` — xcodebuild only forwards env vars into
the simulator test process when they carry the `TEST_RUNNER_` prefix, which it
strips) so a missing reference is a hard failure.

References must match the renderer that verifies them. CI verifies on
**Xcode 16.4 / iOS 18.1**; recording on a different local toolchain (e.g.
Xcode 26 / iOS 26) can yield font/metric drift and perpetual CI diffs. Prefer
recording on CI's renderer via the **CI record path** below; use the local
workflow only when your local simulator runtime matches CI.

**CI record path (recommended — matches CI's renderer exactly):**

1. Push your feature branch (with the new snapshot test added).
2. Actions tab → **CI** workflow → **Run workflow** → set `record_snapshots = true`
   on your branch. The run records references on CI's iOS 18.1 simulator and is
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
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
# tests will "fail" with "Record mode is on" — that is expected
git add ios/ActTests/__snapshots__/
git commit -m "chore(snapshots): record reference PNGs for <feature>"
# run tests again without the env var to confirm they pass
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

> **Device consistency:** Reference PNGs render at `ViewImageConfig.iPhone13Pro`
> layout dimensions (deterministic across simulators), but always pass the
> same `-destination` simulator that CI uses (`iPhone 16 Pro`, iOS 18.1) so
> that font hinting and text layout match CI byte-for-byte.

## TestFlight / CI/CD

- **CI**: GitHub Actions (`.github/workflows/ci.yml`) — `design-doc-check`, `swift-lint`, `xcode-test` run on every branch push (and on fork PRs; same-repo PRs reuse the push run's checks, attached by head SHA). SwiftLint is version-pinned (`SWIFTLINT_VERSION` in `ci.yml`) on Ubuntu; Swift packages are cached via `ios/SourcePackages`.
- **Deploy**: `.github/workflows/deploy.yml` — triggered on version tag push, uploads to TestFlight via Fastlane `:beta` lane (requires `APP_STORE_CONNECT_API_KEY_*` secrets).

## Design

See `docs/design/design.v3.md` (current canonical design). Design files are immutable once merged.
