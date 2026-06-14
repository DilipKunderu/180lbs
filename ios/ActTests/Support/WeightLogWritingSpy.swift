import Foundation
@testable import Act

/// Records `upsertWeightLog` calls for `TodayCoordinatorModel` tests, with no
/// GRDB. Set `thrownError` before the call to simulate a write failure.
final class WeightLogWritingSpy: WeightLogWriting {
    private(set) var savedRows: [WeightLogRow] = []
    var thrownError: Error?

    func upsertWeightLog(_ row: WeightLogRow) throws {
        if let thrownError { throw thrownError }
        savedRows.append(row)
    }
}
