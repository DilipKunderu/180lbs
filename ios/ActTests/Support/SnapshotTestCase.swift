import SnapshotTesting
import SwiftUI
import UIKit
import XCTest

/// Base class for SwiftUI snapshot tests.
///
/// Stores reference PNGs in a single `ios/ActTests/__snapshots__/` directory
/// regardless of which `Snapshots/` sub-folder the test file lives in. Keeping
/// all references in one place makes them easy to review in PRs.
///
/// ## Recording (first run / update)
/// Set the environment variable `SNAPSHOT_TESTING_RECORD=all` and run the
/// test suite once to (re-)generate all reference PNGs, then commit them.
/// CI runs the same simulator (`iPhone 16 Pro` on `macos-15` with iOS 18.1)
/// so reference images recorded locally match CI byte-for-byte.
///
/// ```bash
/// cd ios
/// xcodegen generate
/// SNAPSHOT_TESTING_RECORD=all xcodebuild test \
///   -project Act.xcodeproj -scheme Act \
///   -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1' \
///   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
/// ```
///
/// CI explicitly sets `SNAPSHOT_TESTING_RECORD=never` so a missing reference
/// image is a hard failure rather than a silent record-and-pass. This enforces
/// that every snapshot test ships its reference image in the same commit.
class SnapshotTestCase: XCTestCase {

    /// Absolute path to `ios/ActTests/__snapshots__/` computed at build time
    /// from this file's location so it works on any clone depth.
    ///
    /// Path decomposition:
    ///   `…/ios/ActTests/Support/SnapshotTestCase.swift`
    ///              ↑ deletingLastPathComponent() twice → `…/ios/ActTests/`
    static let snapshotDirectory: String = {
        URL(fileURLWithPath: #file)     // …/Support/SnapshotTestCase.swift
            .deletingLastPathComponent() // …/Support/
            .deletingLastPathComponent() // …/ActTests/
            .appendingPathComponent("__snapshots__")
            .path
    }()

    // MARK: - Assertion helper

    /// Renders `view` at iPhone 13 Pro layout dimensions in dark mode and
    /// asserts (or records) a snapshot in `ios/ActTests/__snapshots__/`.
    ///
    /// `ViewImageConfig.iPhone13Pro` fixes the layout dimensions independent of
    /// the host simulator device, so renders are deterministic across local /
    /// CI as long as the simulator OS matches (iOS 18.1).
    ///
    /// ## Why `verifySnapshot` and not `assertSnapshot`?
    /// `assertSnapshot` (≥ 1.17) no longer accepts a `snapshotDirectory:`
    /// parameter — by default it writes to a `__Snapshots__/` directory next
    /// to the test file. We want all references in a single
    /// `ios/ActTests/__snapshots__/` directory regardless of which `Snapshots/`
    /// sub-folder the test lives in, so this helper calls `verifySnapshot`
    /// directly (which still accepts `snapshotDirectory:`) and surfaces the
    /// returned failure message via `XCTFail`. This is the migration pattern
    /// recommended by the library's own `verifySnapshot` docstring.
    ///
    /// Pass `file:` and `testName:` only if you need to override the defaults;
    /// Swift's default-argument macros capture the correct call site automatically.
    func assertViewSnapshot<V: View>(
        _ view: V,
        named name: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let failure = verifySnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone13Pro),
                traits: UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .dark)
                ])
            ),
            named: name,
            record: nil,
            snapshotDirectory: Self.snapshotDirectory,
            file: file,
            testName: testName,
            line: line
        )
        if let failure {
            XCTFail(failure, file: file, line: line)
        }
    }

    // MARK: - Bootstrap-only skip helper

    /// **BOOTSTRAP PATH ONLY.** Skips the calling test when no reference PNG
    /// matching `token` exists in `ios/ActTests/__snapshots__/`.
    ///
    /// ## Contributor contract
    /// Real feature snapshot tests (`Cmd*`, `Onb*`, `LA*`, `Widget*`) **MUST
    /// commit their reference PNGs in the same PR that adds the test** and
    /// **MUST NOT call this helper**. CI hard-fails on a snapshot mismatch
    /// (`SNAPSHOT_TESTING_RECORD=never`); calling this helper bypasses that
    /// hard-fail by turning a missing reference into a silent skip, which
    /// erodes coverage if used outside the bootstrap path.
    ///
    /// The only sanctioned use is the test-scaffold's `ContentView` sample,
    /// which proves the harness compiles before a real reference is recorded.
    /// Once the first feature snapshot test lands with its reference PNG, the
    /// sample test should be removed and this helper can be deprecated.
    ///
    /// ## Behaviour
    /// `token` is matched as a case-sensitive substring against PNG filenames.
    /// When the test skips, this helper emits an `XCTAttachment` named
    /// `"BOOTSTRAP-SKIP-<token>"` with a human-readable warning so the skip
    /// is visible in test logs and `.xcresult` bundles — not silent.
    ///
    /// In record mode (`SNAPSHOT_TESTING_RECORD=all` or `missing`) the helper
    /// never skips: skipping there would prevent `assertViewSnapshot` from
    /// writing the reference this helper is waiting for — the record run would
    /// silently produce nothing (the bug that motivated `environment:` being
    /// injectable; see `SnapshotBootstrapSkipTests`).
    func XCTBootstrapSkipIfReferenceMissing(
        named token: String,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws {
        let recordMode = environment["SNAPSHOT_TESTING_RECORD"]
        if recordMode == "all" || recordMode == "missing" {
            return
        }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: Self.snapshotDirectory)) ?? []
        let hasMatch = files.contains { $0.hasSuffix(".png") && $0.contains(token) }
        guard hasMatch else {
            let warning = """
                BOOTSTRAP SKIP — no reference PNG matching '\(token)' in ios/ActTests/__snapshots__/.

                Run with SNAPSHOT_TESTING_RECORD=all locally and commit the generated image.
                See README → Snapshot tests — recording reference images.

                NOTE: this skip is the bootstrap-only path. Real feature snapshot tests
                MUST commit references in the same PR and MUST NOT use this helper.
                """
            let attachment = XCTAttachment(string: warning)
            attachment.name = "BOOTSTRAP-SKIP-\(token)"
            attachment.lifetime = .keepAlways
            add(attachment)
            throw XCTSkip(warning)
        }
    }
}
