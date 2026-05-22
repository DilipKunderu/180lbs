import XCTest
@testable import Act

/// Sample-shape snapshot test that proves the SnapshotTestCase harness works.
///
/// This is the only snapshot test that should live in this file. All real
/// feature snapshot tests are added in their respective todos (Cmd*/Onb*/LA*/
/// Widget*) once those views exist.
///
/// Reference PNGs live in `ios/ActTests/__snapshots__/`. When no PNGs are
/// committed yet, this test skips so CI stays green. To add a reference:
///
/// ```bash
/// cd ios
/// SNAPSHOT_TESTING_RECORD=all xcodebuild test \
///   -project Act.xcodeproj -scheme Act \
///   -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=18.1' \
///   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
/// git add ios/ActTests/__snapshots__/ && git commit -m "chore(snapshots): record ContentView reference"
/// ```
final class ContentViewSnapshotTests: SnapshotTestCase {

    func test_contentView_renders_dark_iphone13pro() throws {
        try skipIfNoReferencePNGs()
        assertViewSnapshot(ContentView())
    }

    // MARK: - Private

    /// Skips the test when the `__snapshots__/` directory contains no PNGs.
    ///
    /// This guard keeps CI green on the first push (before any reference images
    /// are committed) while still asserting equality once PNGs are present.
    /// CI sets `SNAPSHOT_TESTING_RECORD=never` so a mismatch is a hard failure.
    private func skipIfNoReferencePNGs() throws {
        let snapshotDir = URL(fileURLWithPath: Self.snapshotDirectory)
        let hasPNGs = ((try? FileManager.default.contentsOfDirectory(atPath: snapshotDir.path)) ?? [])
            .contains { $0.hasSuffix(".png") }
        guard hasPNGs else {
            throw XCTSkip(
                "No reference PNGs in ios/ActTests/__snapshots__/ yet. " +
                "Run with SNAPSHOT_TESTING_RECORD=all locally and commit the generated images. " +
                "See README → Snapshot tests — recording reference images."
            )
        }
    }
}
