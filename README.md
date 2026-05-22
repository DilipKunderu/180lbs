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
    └── ActTests.swift
```

### Target bundle IDs

| Target | Bundle ID |
|--------|-----------|
| App | `com.act.coach` |
| WidgetKit extension | `com.act.coach.Widgets` |
| Live Activity extension | `com.act.coach.LiveActivity` |
| Test bundle | `com.act.coach.Tests` |

All four targets are enrolled in App Group `group.com.act.coach` (shared GRDB/SQLite container).

## Capabilities wired (app target)

| Capability | Notes |
|-----------|-------|
| HealthKit (read + write) | Usage strings in Info.plist |
| CloudKit (`iCloud.com.act.coach`) | Private database for cross-device sync/backup |
| App Groups (`group.com.act.coach`) | Shared SQLite mirror for extensions |
| Push Notifications (entitlement only) | Required by ActivityKit; no APNs key exists |
| Background Fetch + Processing | `BGProcessingTask` id: `com.act.coach.weekly-insight` |
| Live Activities (`NSSupportsLiveActivities`) | ActivityKit via Live Activity extension |

## Running tests locally

```bash
cd ios
xcodegen generate
xcodebuild test \
  -project Act.xcodeproj \
  -scheme Act \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.1' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

## TestFlight / CI/CD

- **CI**: GitHub Actions (`.github/workflows/ci.yml`) — `design-doc-check`, `swift-lint`, `xcode-test` run on every push/PR.
- **Deploy**: `.github/workflows/deploy.yml` — triggered on version tag push, uploads to TestFlight via Fastlane `:beta` lane (requires `APP_STORE_CONNECT_API_KEY_*` secrets).

## Design

See `docs/design/design.v3.md` (current canonical design). Design files are immutable once merged.
