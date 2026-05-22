import XCTest
@testable import Act

/// Sample-shape snapshot test that proves the SnapshotTestCase harness works.
///
/// This is the **only** test sanctioned to call the bootstrap-skip helper.
/// All real feature snapshot tests (Cmd*/Onb*/LA*/Widget*) must commit their
/// reference PNGs in the same PR that adds the test and must NOT skip on a
/// missing reference. Once the first feature snapshot test lands, this file
/// can be removed.
///
/// Reference PNGs live in `ios/ActTests/__snapshots__/`. While no PNG matching
/// this test's token is committed, the test skips so CI stays green. To add
/// the reference:
///
/// ```bash
/// cd ios
/// SNAPSHOT_TESTING_RECORD=all xcodebuild test \
///   -project Act.xcodeproj -scheme Act \
///   -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1' \
///   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
/// git add ios/ActTests/__snapshots__/ && git commit -m "chore(snapshots): record ContentView reference"
/// ```
final class ContentViewSnapshotTests: SnapshotTestCase {

    func test_contentView_renders_dark_iphone13pro() throws {
        // BOOTSTRAP-ONLY: see SnapshotTestCase.XCTBootstrapSkipIfReferenceMissing
        // doc-comment. Real feature snapshot tests must NOT call this.
        try XCTBootstrapSkipIfReferenceMissing(named: "ContentView")
        assertViewSnapshot(ContentView())
    }
}
