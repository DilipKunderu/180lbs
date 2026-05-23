import CloudKit
import XCTest
@testable import Act

/// E3: `DEVIATION_LOG.photo` must encode/decode as a `CKAsset` per
/// `design.v3 §Data model:259`. The CKAsset wraps the same local fileURL the
/// caller passed in; bytes are never read on the device — CloudKit takes
/// care of upload/download out of band.
final class DeviationLogCKRecordTests: XCTestCase {
    func test_deviationLog_photoRoundTripsAsCKAsset() throws {
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-deviation-\(UUID().uuidString).jpg")
        addTeardownBlock { try? FileManager.default.removeItem(at: tempPath) }
        FileManager.default.createFile(atPath: tempPath.path, contents: Data([0x00, 0x01]))

        let row = DeviationLogRow(
            id: UUID(),
            mealDate: "2026-05-22",
            loggedAt: LocalStoreTestSupport.utcDate("2026-05-22T18:10:00Z"),
            reason: "social",
            photoURL: tempPath,
            kcalEst: 1800,
            proteinGEst: 90
        )

        let record = row.toCKRecord()
        XCTAssertNotNil(record["photo"] as? CKAsset, "DEVIATION_LOG.photo must encode as CKAsset")
        XCTAssertEqual((record["photo"] as? CKAsset)?.fileURL, tempPath)

        guard let recovered = DeviationLogRow(record: record) else {
            return XCTFail("CKRecord round-trip must succeed for DeviationLogRow")
        }
        XCTAssertEqual(recovered.photoURL, tempPath)
    }
}
