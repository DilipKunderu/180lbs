import XCTest
@testable import Act

/// Sample-shape snapshot test that proves the SnapshotTestCase harness works.
///
/// This is the only snapshot test that should live in this file. All real
/// feature snapshot tests are added in their respective todos (Cmd*/Onb*/LA*/
/// Widget*) once those views exist.
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
        // Per-test skip token: matched as a substring against PNG filenames in
        // __snapshots__/ so committing an unrelated feature's reference does
        // NOT force this test to also have its reference committed.
        try skipIfReferenceMissing(named: "ContentView")
        assertViewSnapshot(ContentView())
    }
}
