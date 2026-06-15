import Foundation
import XCTest
@testable import Act

final class BodyMassTests: XCTestCase {

    // MARK: - Empty input

    func test_latestBodyMassLb_returnsNilForEmptySamples() {
        let result = latestBodyMassLb(from: [])

        XCTAssertNil(result)
    }

    // MARK: - Single sample conversion

    func test_latestBodyMassLb_convertsSingleSampleFromKgToLb() throws {
        let sample = (date: Date(), kg: 100.0)

        let result = try XCTUnwrap(latestBodyMassLb(from: [sample]))

        let expected = 100.0 * kgToLbFactor // 220.46226218
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    // MARK: - Most-recent-by-date selection

    func test_latestBodyMassLb_selectsSampleWithLatestDateNotArrayPosition() throws {
        // Three samples whose array order does NOT match chronological order.
        // The middle element in the array has the latest date — if the function
        // naively picks first or last in the array it will return the wrong lb.
        let oldest = (date: date("2026-01-01T08:00:00Z"), kg: 90.0)
        let newest = (date: date("2026-01-03T08:00:00Z"), kg: 85.0) // latest date, middle index
        let middle = (date: date("2026-01-02T08:00:00Z"), kg: 87.5)

        let result = try XCTUnwrap(latestBodyMassLb(from: [oldest, newest, middle]))

        // Only the 85.0 kg sample is correct; 90.0 or 87.5 would reveal a bug.
        let expected = 85.0 * kgToLbFactor
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    // MARK: - Conversion constant precision

    func test_latestBodyMassLb_convertsKnownBodyWeightAccurately() throws {
        // 81.6466 kg is the canonical "180 lb" anchor for this app.
        let sample = (date: Date(), kg: 81.6466)

        let result = try XCTUnwrap(latestBodyMassLb(from: [sample]))

        XCTAssertEqual(result, 180.0, accuracy: 0.01)
    }

    // MARK: - Private helpers

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let parsed = formatter.date(from: value) else {
            fatalError("invalid test date: \(value)")
        }
        return parsed
    }
}
