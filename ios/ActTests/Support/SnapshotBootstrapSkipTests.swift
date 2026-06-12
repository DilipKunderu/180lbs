import XCTest
@testable import Act

/// Behavior of `SnapshotTestCase.XCTBootstrapSkipIfReferenceMissing` across
/// record modes.
///
/// Regression context: CI's `record_snapshots=true` dispatch run produced no
/// reference PNGs because the bootstrap helper skipped the test before
/// `assertViewSnapshot` could record — the helper ignored
/// `SNAPSHOT_TESTING_RECORD`. In record mode the helper must let the test
/// proceed so the reference gets written.
final class SnapshotBootstrapSkipTests: SnapshotTestCase {

    private let missingToken = "NoSuchReferenceToken"

    func test_doesNotSkip_whenRecordModeAll_andReferenceMissing() {
        XCTAssertNoThrow(
            try XCTBootstrapSkipIfReferenceMissing(
                named: missingToken,
                environment: ["SNAPSHOT_TESTING_RECORD": "all"]
            )
        )
    }

    func test_doesNotSkip_whenRecordModeMissing_andReferenceMissing() {
        XCTAssertNoThrow(
            try XCTBootstrapSkipIfReferenceMissing(
                named: missingToken,
                environment: ["SNAPSHOT_TESTING_RECORD": "missing"]
            )
        )
    }

    func test_skips_whenNotRecording_andReferenceMissing() {
        XCTAssertThrowsError(
            try XCTBootstrapSkipIfReferenceMissing(
                named: missingToken,
                environment: [:]
            )
        ) { error in
            XCTAssertTrue(error is XCTSkip, "expected XCTSkip, got \(type(of: error))")
        }
    }

    func test_skips_whenRecordModeNever_andReferenceMissing() {
        XCTAssertThrowsError(
            try XCTBootstrapSkipIfReferenceMissing(
                named: missingToken,
                environment: ["SNAPSHOT_TESTING_RECORD": "never"]
            )
        ) { error in
            XCTAssertTrue(error is XCTSkip, "expected XCTSkip, got \(type(of: error))")
        }
    }
}
