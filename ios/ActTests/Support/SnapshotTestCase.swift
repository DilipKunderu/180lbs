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
/// Set `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all` and run the test suite once
/// to (re-)generate all reference PNGs, then commit them. The `TEST_RUNNER_`
/// prefix is mandatory: xcodebuild forwards only `TEST_RUNNER_`-prefixed
/// variables into the simulator test process (stripping the prefix); a bare
/// `SNAPSHOT_TESTING_RECORD=all` never reaches the tests. CI runs the same
/// simulator (`iPhone 17 Pro` on `macos-26` with iOS 26.5) so reference
/// images recorded locally match CI byte-for-byte.
///
/// ```bash
/// cd ios
/// xcodegen generate
/// TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
///   -project Act.xcodeproj -scheme Act \
///   -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
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
    /// CI as long as the simulator OS matches (iOS 26.5).
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
}
