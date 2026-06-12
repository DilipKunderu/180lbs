# CI/Orchestration Optimization — Act.

Created 2026-06-12 from an AI planning session (plan mode review of build/CI/dev-workflow orchestration).

## Context

A deep review of the project's orchestration (CI workflows, deploy pipeline, scripts, hooks, XcodeGen setup) found the methodology fundamentally sound — concurrency cancellation, design-doc immutability gate, strict lint, snapshot record path, and conditional FoundationModels linking are all well designed. But three concrete inefficiencies cost real CI time/money on every push, and one piece of the snapshot pipeline has never been exercised:

1. **Every push to a PR branch runs the full pipeline twice.** `ci.yml` triggers on `push` (all branches, `branches-ignore: []`) *and* `pull_request` → main. The two events land in different concurrency groups (`ci-refs/heads/<branch>` vs `ci-refs/pull/N/merge`), so once a PR is open, each push burns 2× the macOS minutes (~20 runner-minutes per push across the two macOS jobs).
2. **No SPM caching.** `xcode-test` resolves and rebuilds all Swift packages (GRDB, swift-snapshot-testing, swift-syntax, …) from scratch every run — the dominant avoidable cost, several minutes per run.
3. **SwiftLint runs on a macOS runner with an unpinned version.** `brew install swiftlint` pulls latest-at-runtime (drift vs. local), and macOS runners bill at 10× Ubuntu on GitHub-hosted plans. The lint job needs no Xcode.
4. **Zero snapshot reference PNGs exist** (`__snapshots__/` holds only `.gitkeep`). `ContentViewSnapshotTests` self-skips via the bootstrap helper, so the CI record path (`record_snapshots=true` → artifact → commit) has never been run end-to-end. Phase 9.1b (onboarding views) will depend on this pipeline working.

Out of scope, deliberately: TestFlight signing (`deploy.yml` TODO at line 37) — it is cleanly gated on the ASC secrets and needs an Apple Developer Program decision (fastlane match repo); separate sub-task.

## Simulator-preview question (answered, no action required)

The absence of simulator previews so far is **correct sequencing, not a planning gap**. The app *is* launchable today — `@main ActApp` renders the placeholder `ContentView` ("Act." on black) — but it's the only view in the target; `Onboarding/` is renderer-free by design (per `docs/architecture/onboarding-interface.md`, views are explicitly deferred to 9.1b). There is nothing to visually validate yet. Visual validation enters with 9.1b via the already-built snapshot harness; minting the bootstrap PNG (step 4 below) makes that lane proven before 9.1b needs it. An XCUITest launch smoke test was considered and deferred — snapshot tests cover rendering and XCUITest would add minutes to every CI run for little signal at this stage.

## Plan

Branch: `chore/ci-orchestration` cut from `main` (current `feat/onboarding-9.1b` has no commits and is unrelated; leave it).

### 1. De-duplicate CI runs — `.github/workflows/ci.yml`

Keep both triggers (push runs on feature branches are actively used pre-PR — history shows useful failures caught there), but skip the redundant `pull_request` run for same-repo PRs. Add to **all three jobs**:

```yaml
if: github.event_name != 'pull_request' ||
    github.event.pull_request.head.repo.full_name != github.repository
```

GitHub attaches check runs by head SHA, so the push-triggered run still shows on the PR. Fork PRs (the only case the `pull_request` event uniquely covers) still run.

### 2. Cache Swift packages — `xcode-test` job

- Add `-clonedSourcePackagesDirPath SourcePackages` to both the `-resolvePackageDependencies` step and the `xcodebuild test` invocation (keeps packages in `ios/SourcePackages`, out of ephemeral DerivedData).
- Add `actions/cache` on `ios/SourcePackages`, keyed on `hashFiles('ios/project.yml')` (no committed `Package.resolved` — the project is generated), with a `restore-keys` prefix fallback so partial hits still help.

### 3. Move lint to Ubuntu with a pinned SwiftLint — `swift-lint` job

- `runs-on: ubuntu-latest`; install a **pinned** SwiftLint release (official prebuilt Linux binary from the GitHub release, version chosen to match local — check `swiftlint version` locally first).
- The custom rules in `.swiftlint.yml` (hex-color ban) are regex rules — Linux-safe. Verify with a local container run or just the CI run itself.
- Drops ~10 macOS-billed minutes per push-cycle to ~1 Ubuntu minute and kills the version-drift problem. Document the pinned version so the pre-push hook (`.githooks/`) can match.

### 4. Mint the bootstrap snapshot reference (process, not code)

Run the **CI** workflow via `workflow_dispatch` with `record_snapshots=true` on the branch, download the `snapshots-<run_id>` artifact, commit the `ContentView` PNG. This converts `ContentViewSnapshotTests` from self-skipping to a real assertion and proves the record→artifact→commit→verify loop before 9.1b relies on it.

### 5. Persist this plan into the repo

Copy this plan to `plans/ci-orchestration-optimization.md` (repo root `plans/`, per global rules) in the same branch.

## Files touched

- `.github/workflows/ci.yml` — items 1–3
- `ios/ActTests/__snapshots__/` — new committed PNG (item 4)
- `plans/ci-orchestration-optimization.md` — new (item 5)

## Verification

Workflow YAML has no unit-test harness; verification is the pipeline itself:

1. Push the branch → exactly **one** CI run (push event); after opening the PR, push again → still one run, and its checks appear on the PR.
2. First run populates the SPM cache; a second push shows a cache hit and a measurably faster `xcode-test` job (baseline ~10 min; expect a multi-minute drop).
3. `swift-lint` job green on Ubuntu with the pinned version; `swiftlint lint --strict ios/` still passes locally.
4. Record-mode `workflow_dispatch` run uploads the PNG artifact; after committing it, the next normal run executes (not skips) `ContentViewSnapshotTests` and passes.
5. Full suite stays green: the standard `xcodebuild test` command from CLAUDE.md.
