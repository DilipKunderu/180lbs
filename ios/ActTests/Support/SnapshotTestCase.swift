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
///
/// ```bash
/// cd ios
/// xcodegen generate
/// SNAPSHOT_TESTING_RECORD=all xcodebuild test \
///   -project Act.xcodeproj -scheme Act \
///   -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=18.1' \
///   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
/// ```
///
/// Tests in CI run without `SNAPSHOT_TESTING_RECORD`; the library defaults to
/// `.missing` which **fails** if a reference PNG is absent. This enforces that
/// every snapshot test ships its reference image in the same commit.
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

    /// Renders `view` at iPhone 13 Pro dimensions in dark mode and asserts
    /// (or records) a snapshot in `ios/ActTests/__snapshots__/`.
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
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone13Pro),
                traits: UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .dark)
                ])
            ),
            named: name,
            snapshotDirectory: Self.snapshotDirectory,
            file: file,
            testName: testName,
            line: line
        )
    }
}
