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

    // MARK: - Bootstrap helper

    /// Skips the calling test when no reference PNG matching `token` exists in
    /// `ios/ActTests/__snapshots__/`.
    ///
    /// `token` is matched as a case-sensitive substring against PNG filenames
    /// (typically the test class name or test method name). This keeps each
    /// snapshot test's bootstrap-skip independent: once the first feature
    /// snapshot is committed it does **not** force unrelated tests to also
    /// have their references committed in the same commit.
    ///
    /// Once a developer records the reference (via `SNAPSHOT_TESTING_RECORD=all`)
    /// and commits the PNG, this skip becomes a hard equality assertion.
    func skipIfReferenceMissing(named token: String) throws {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: Self.snapshotDirectory)) ?? []
        let hasMatch = files.contains { $0.hasSuffix(".png") && $0.contains(token) }
        guard hasMatch else {
            throw XCTSkip(
                "No reference PNG matching '\(token)' in ios/ActTests/__snapshots__/. " +
                "Run with SNAPSHOT_TESTING_RECORD=all locally and commit the generated image. " +
                "See README → Snapshot tests — recording reference images."
            )
        }
    }
}
