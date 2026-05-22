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

## Persistence layer

Act. uses a local-first persistence split defined by `docs/design/design.v3.md` §Data model: all 15 user-domain entities are represented as CloudKit `CKRecord` types, and the app reads/writes through a GRDB SQLite mirror for fast on-device queries and offline-first writes. The SQLite file is shared across the app, WidgetKit extension, and Live Activity extension via the App Group container path `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.act.coach")!.appendingPathComponent("act.sqlite")`, so every runtime surface sees the same data without cross-sandbox read failures.

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
`ios/ActTests/__snapshots__/`. CI sets `SNAPSHOT_TESTING_RECORD=never` so a
missing reference is a hard failure.

**First run / update workflow:**

```bash
cd ios
xcodegen generate
SNAPSHOT_TESTING_RECORD=all xcodebuild test \
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

- **CI**: GitHub Actions (`.github/workflows/ci.yml`) — `design-doc-check`, `swift-lint`, `xcode-test` run on every push/PR.
- **Deploy**: `.github/workflows/deploy.yml` — triggered on version tag push, uploads to TestFlight via Fastlane `:beta` lane (requires `APP_STORE_CONNECT_API_KEY_*` secrets).

## Design

See `docs/design/design.v3.md` (current canonical design). Design files are immutable once merged.
