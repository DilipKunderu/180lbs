# Design-progression reconciliation — drift & gap fill (team skill)

Created 2026-06-13 from an AI planning session.
Source of truth: `docs/design/design.v4.md` (current per `docs/design/CURRENT`), with a new `design.v5.md` to be authored as part of this work.

## Context

Several PRs landed on this project under a pair-programming skill that wasn't cleanly
ported from Cursor to Claude Code, and a couple landed with no skill at all. The user
asked to: pull latest `main`, use the **team** skill, and meticulously verify the
shipped code against the original design progression — identifying and filling drifts
(shipped-but-wrong) and gaps (claimed-but-missing/incomplete).

Three parallel audits (persistence, onboarding/HealthKit/tokens, hygiene) against
`design.v4.md` produced an evidence-backed inventory. The product is intentionally
only partially built (onboarding, the 15-entity persistence schema, HealthKit reads,
design tokens); the Today coordinator, notification *registration*, CloudKit inbound
sync, AI weekly review, widgets/Live-Activity content, and most write-side invariants
are **deferred future milestones, not gaps**. This pass fixes only what the shipped
surfaces got wrong or left half-done.

**Decisions (user-confirmed):** full **A+B+C** scope; **author `design.v5`** to
reconcile the two internal design contradictions; **defer** TestFlight deploy signing
(needs the user's Apple Team ID + ASC secrets).

### Git state (verified)
- The local branch `chore/design-v4-reconcile` produces a tree **byte-identical** to
  `origin/main`; PR #16 squash-merged exactly this work. The two `design.v4.md` blobs
  are identical. No real divergence.
- Local `main` is **1 commit behind** `origin/main` (missing the #16 squash commit) and
  is fast-forwardable.
- Five local feature branches are squash-merged orphans, prunable.

### Toolchain (verified this session)
- Local now has **Xcode 26.5, iOS 26.5 runtime, and iPhone 17 Pro sims** — it matches CI
  exactly. The team-skill **red/green TDD gates run locally**; no CI-only mode needed.
- `state.json` `test_command` is stale (points at `iPhone 16 Pro / OS=18.1 / -workspace`)
  and `last_session_summary` wrongly claims local lacks the runtime. Both must be fixed
  before the team run (finding 1.1).

## Audit inventory (what we're fixing)

Severity: ✱error  ·warn  ∘info. "(C)" = architect-adjudication item.

**Tier A — correctness (shipped-but-wrong / claimed-but-missing)**
- G1 ✱ `current_weight_lb_cached` never refreshed on `upsertWeightLog` (design constraint requires refresh-on-write). `LocalStore.swift:128`.
- G2 ✱ `adherence_pct_cached` never refreshed on any write; no formula pinned. `LocalStore.swift:363`.
- G3 · profile CKRecord not propagated after weight/meal writes (follows from G1/G2).
- G4 · `relapse_log` has no query-before-upsert; the `UNIQUE(smoke_check_id)` constraint will *error* (not upsert) on resubmit. `LocalStore.swift:231`, `LocalStoreMigrations.swift:152`.
- GAP-ONB-1 ✱ notification **permission** never requested. Coordinator fires a Health authorizer on leaving `.health` but has no `.notifications` branch. `OnboardingCoordinatorModel.swift:63-76`. (Registration stays deferred — only `requestAuthorization` is in scope, per `onboarding-interface.md` §why + §5.)
- DRIFT-ONB-2 · `OnbHealthView` discloses 6 read types, omits "Dietary water" (design Integrations lists 7). `OnbHealthView.swift:12`. *Touches a snapshot reference.*
- D2 · `DEVIATION_LOG` CKRecord key is `"photo"`, design/Row use `photo_url`. `DeviationLogCKRecord.swift:18,33`.
- 1.1 ✱ `state.json` `test_command` stale (device/OS/workspace-vs-project) + stale `last_session_summary`.
- 1.2 · `project.yml` `xcodeVersion: "16.2"` while CI runs `macos-26`. Bump to `26.0`.
- 4.1 ✱ local `main` behind `origin/main`; fast-forward.

**Tier B — test-coverage hardening**
- 2.1 · delete `ActTests/ActTests.swift` no-op placeholder (real tests live in subdirs).
- 2.2/2.3 · 8 entities (Grocery, LiftLog, LiftSession, Swim, Urge, Walk, Weight, Rotation) have **no** CKRecord round-trip or Row insert/fetch tests.
- GAP-ONB-2 · no test pins `OnboardingStep.allCases` order/count.
- GAP-HK-1 · no test pins `HealthKitReadType`/`WriteType` membership (guards against silent permission creep).
- GAP-TOKEN-1 · `ACTTokensTests` only asserts accent *distinctness*, not the OKLCH→Display-P3 component values.

**Tier C — architect-adjudicated**
- D1 (C) `triggers_json` / `items_json` SQLite columns disagree with CKRecord keys (`triggers`/`items`) and the design field names. Pre-TestFlight, so options: edit the initial migration vs add a rename migration. Architect picks.
- D3 (C) **Design contradiction**: Flow 4 + interface §4 + code all intend a **day-0** WITHDRAWAL_STATE bootstrap row, but the constraint bullet says rows exist only for `[1,7]`. Code is right; the doc bullet is the drift. → resolve in `design.v5`. **Do NOT change code to day-1** (the audit's naive suggestion would break Flow 4).
- DRIFT-ONB-1 (C) `quit_date`/`start_weight_lb` immutability is mandated at the *type level* by interface §2/§3, but `upsertProfile(ProfileRow)` exposes them mutably and the `ProfileMutation` sketch is marked superseded. Default: introduce a `ProfileMutation` type that omits the two immutable fields and switch the post-bootstrap write path to it. Architect confirms now-vs-defer (no Settings edit UI exists yet).

**Deferred this pass (NOT fixed):** 3.1 deploy signing (needs user creds); 3.2 Hidrate
bundle-prefix TODO (hardware-gated); G5 + other entities' write-side invariants, Today
coordinator (`ContentView` placeholder), notification *registration*, CloudKit inbound
sync — all future milestones.

## Approach

Run the **team** skill end-to-end. The orchestrator never writes code; it drives the
four subagents through the red→green→review loop per sub-task, with the architect
authoring `design.v5` and doing the drift-check, and Principal + Architect as reviewers.

### Step 0 — Git sync & branch hygiene (orchestrator, pre-skill)
1. `git switch main && git pull --ff-only origin main` (4.1).
2. Start a fresh working branch off updated `main`, e.g. `chore/design-v5-reconcile`.
3. Prune squash-merged orphans: `git branch -d chore/design-v4-reconcile chore/ci-orchestration chore/target-latest-ios feat/onboarding-9.1b feat/onboarding-healthkit-cta` (after confirming each is content-merged). Remote prune optional.

### Step 1 — Team-skill session setup
1. **Fix `state.json` first (finding 1.1)** — `test_command` →
   `xcodebuild test -project Act.xcodeproj -scheme Act -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`; correct the stale `last_session_summary`. (This is both a required setup step and an audit fix.)
2. Toolchain check: `cd ios && xcodegen generate` then `xcodebuild -list -project Act.xcodeproj` — confirm the runner works (it does locally now).
3. Rules preamble load + drift-check against `~/.claude/CLAUDE.md` (per skill).
4. Print model assignments (principal=opus, senior_a/b=sonnet, architect=fable) and confirm ≥2 distinct for judge rotation.

### Step 2 — Design precheck & `design.v5` (architect)
- Read `CURRENT` (design.v4.md) as required reading.
- Architect `AUTHOR_DESIGN` → `docs/design/design.v5.md` (immutable, frontmatter with `supersedes: design.v4.md`, non-empty `changelog_vs_previous`), then orchestrator swaps `CURRENT` → `design.v5.md`. v5 carries v4 forward verbatim except:
  - Reconcile WITHDRAWAL_STATE: state explicitly that a **day-0 bootstrap row** is written atomically with PROFILE, and the `[1,7]` range describes the *Today-overlay active window*, not row existence (D3).
  - **Pin the `adherence_pct_cached` formula** (7-day rolling; define the numerator events — meal_log/deviation present, smoke_check='clean', lift_session.completed on lift days — and denominator) so G2 has a spec (G2).
  - Optionally note the JSON column naming canonical form for D1.
- Run through the rotating PLAN_JUDGE; verify the design-doc-check invariants (`bash scripts/check-design-docs.sh`) stay green (v4 untouched, only new file + CURRENT swap).

### Step 3 — Implementation sub-tasks (each: red→green→review per skill)
Grouped to keep each sub-task one crisp responsibility. Order puts spec/setup first,
correctness next, then coverage.

1. **persistence-caches** (G1, G3): add `recomputeCurrentWeightCached(db:)` mirroring `recomputeCleanStreakDays`; call in `upsertWeightLog` write block; propagate profile CloudDelta. Red test: cache updates after weigh-in.
2. **adherence-cache** (G2): implement `recomputeAdherencePct(db:)` per the v5 formula; call from meal/deviation/smoke/lift write blocks; propagate profile delta. Red tests for each trigger + the rolling window.
3. **relapse-upsert** (G4): query existing relapse by `smoke_check_id`, reuse its PK before `save`. Red test: second submit upserts, no constraint error.
4. **notification-permission** (GAP-ONB-1): add `NotificationAuthorizationRequesting` seam (parallel to `HealthAuthorizationRequesting`), inject into `OnboardingCoordinatorModel`, fire best-effort on leaving `.notifications`. Red test with a spy authorizer (mirror `SpyHealthAuthorizer`).
5. **deviation-photo-key** (D2): CKRecord key `"photo"` → `"photo_url"`; extend `DeviationLogCKRecordTests` round-trip.
6. **json-column-naming** (D1, architect-chosen mechanism): align SQLite columns with CKRecord keys / design field names; add the chosen migration; update Row `CodingKeys`. Tests: Row round-trip + (if new migration) migration test.
7. **profile-mutation-immutability** (DRIFT-ONB-1, if architect confirms now): add `ProfileMutation` (omits `quitDate`/`startWeightLb`); switch the post-bootstrap profile write path to it; red test that the immutable fields can't be changed via the public API.
8. **healthview-dietary-water** (DRIFT-ONB-2): add "Dietary water" to `OnbHealthView.readTypes`; **re-record the `OnbHealth` snapshot reference** on the matching renderer (local == CI now) per the skill's snapshot variant; commit the new PNG with the test.
9. **coverage-persistence** (2.2/2.3): one CKRecord encode/decode round-trip + one Row insert/fetch per untested entity (Grocery, LiftLog, LiftSession, Swim, Urge, Walk, Weight, Rotation). These are regression-locking tests (skill snapshot/golden variant n/a; standard red-by-temporarily-breaking-a-field if needed, else accept as regression-lock per the green-already path).
10. **coverage-assertions** (GAP-ONB-2, GAP-HK-1, GAP-TOKEN-1): pin `OnboardingStep.allCases`; pin HealthKit read/write set membership; assert ACTTokens accent Display-P3 components within ±0.005.
11. **toolchain-xcodeversion** (1.2): `project.yml` `xcodeVersion: "26.0"`; `xcodegen generate`. No-behavior escape hatch (config-only).
12. **delete-placeholder-test** (2.1): remove `ActTests/ActTests.swift`. No-behavior; baseline test run must stay green.

After each accept: flip `pair_driver_next`, increment `subtasks_since_architect_check`;
fire the architect drift-check when it reaches `architect_check_every` (3).

### Step 4 — Final review & landing
- Full suite green via the corrected `test_command`.
- `swiftlint lint --strict ios/` clean; `bash scripts/check-design-docs.sh` green.
- Commit per sub-task on the working branch (Conventional Commits, with the global
  `Co-Authored-By: Claude Opus 4.8` trailer). Open one PR per the user's normal flow;
  attach simulator screenshot evidence for the OnbHealthView change (per the
  "simulator screenshots in PRs" memory).
- Copy this plan into the repo at `plans/design-v5-reconcile.md` on the working branch
  (global rule: persist plan docs into the project).

## Critical files
- Design: `docs/design/design.v4.md` (read-only), new `docs/design/design.v5.md`, `docs/design/CURRENT`, `docs/architecture/onboarding-interface.md` (non-versioned; may get a binding bump to v5).
- Persistence: `ios/Act/Persistence/LocalStore.swift`, `LocalStoreMigrations.swift`, `PersistenceSupport.swift`, `Rows/*Row.swift`, `CKRecords/*CKRecord.swift`.
- Onboarding: `ios/Act/Onboarding/OnboardingCoordinatorModel.swift`, `OnboardingStep.swift`, new `NotificationAuthorizationRequesting.swift`, `Views/OnbHealthView.swift`.
- HealthKit: `ios/Act/Service/HealthKit.swift`.
- Tokens: `ios/Act/Design/ACTTokens.swift`.
- Tests: `ios/ActTests/Persistence/*`, `ios/ActTests/Onboarding/*` (reuse `SpyHealthAuthorizer`, `FakeOnboardingProfileStore`, `LocalStoreTestSupport`), `ios/ActTests/Service/HealthKitTests.swift`, `ios/ActTests/ACTTokensTests.swift`, `ios/ActTests/Snapshots/OnbHealthSnapshotTests.swift` + `__snapshots__/`.
- Config: `ios/project.yml`, `/Users/dilipkunderu/.claude/skills/team/state.json`.

## Verification
- **Unit/red→green:** every sub-task shows a real red checkpoint then green via
  `xcodebuild test -project Act.xcodeproj -scheme Act -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`. Single-class runs via `-only-testing:ActTests/<Class>`.
- **Caches (G1/G2):** new tests assert `current_weight_lb_cached` and
  `adherence_pct_cached` update after the relevant writes and that a profile CloudDelta
  is propagated.
- **Notification permission (GAP-ONB-1):** spy authorizer receives exactly one
  `requestAuthorization` on leaving `.notifications`, step advances unconditionally.
- **Snapshot (DRIFT-ONB-2):** new `OnbHealth` reference recorded on the 26.5 renderer;
  re-run with record=never passes.
- **Coverage:** new CKRecord/Row round-trip tests pass; membership/order/token tests pass.
- **Design:** `scripts/check-design-docs.sh` green (v4 unchanged; v5 added; CURRENT→v5).
- **Lint:** `swiftlint lint --strict ios/` clean.
- **App smoke:** launch on iPhone 17 Pro sim, walk onboarding to confirm the Health and
  Push permission prompts both fire and the flow completes into the app; capture
  screenshots for the PR.

## Open items for the architect during the run
- D1 mechanism: edit initial migration (pre-TestFlight, no real data) vs add a rename
  migration. Recommend the latter for forward-safety.
- DRIFT-ONB-1: confirm introducing `ProfileMutation` now vs deferring until a Settings
  edit flow exists. Default: introduce now (interface §2/§3 mandate type-level encoding).
- v5 adherence formula exact definition (numerator events + lift-day handling).
