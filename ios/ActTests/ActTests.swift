import XCTest

/// Smoke-test suite that verifies the project scaffold builds and links correctly.
/// Behavior-level tests (persistence invariants, snapshot tests, scheduler) live
/// in the `test-scaffold` todo and will replace/extend this file.
final class ActTests: XCTestCase {
    func testPlaceholderAlwaysPasses() {
        // Intentional no-op: proves the test target compiles and xcodebuild test has something to run.
        XCTAssertTrue(true)
    }
}
