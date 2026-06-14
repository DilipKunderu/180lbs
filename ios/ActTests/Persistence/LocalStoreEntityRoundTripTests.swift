import GRDB
import XCTest
@testable import Act

/// Regression-locking round-trip coverage for the entity Row + CKRecord types
/// that had no dedicated tests (audit 2.2/2.3): each row encodes to a CKRecord
/// and decodes back unchanged, and survives a GRDB save/fetch. Guards against
/// CKRecord-key and CodingKey/column typos that would otherwise be invisible.
/// DEVIATION_LOG (photo CKAsset) and the entities exercised by LocalStoreTests
/// (PROFILE, MEAL_LOG, SMOKE_CHECK, RELAPSE_LOG, WITHDRAWAL_STATE, HYDRATION_LOG)
/// are covered elsewhere.
final class LocalStoreEntityRoundTripTests: XCTestCase {
    private var queue: DatabaseQueue!

    override func setUpWithError() throws {
        try super.setUpWithError()
        queue = try DatabaseQueue()
        _ = try LocalStore(database: queue, cloudDatabase: nil) // runs migrations
    }

    override func tearDownWithError() throws {
        queue = nil
        try super.tearDownWithError()
    }

    private func date(_ text: String) -> Date { LocalStoreTestSupport.utcDate(text) }

    private func grdbRoundTrip<T: PersistableRecord & FetchableRecord>(_ row: T) throws -> T {
        try queue.write { try row.save($0) }
        return try queue.read { try XCTUnwrap(try T.fetchOne($0)) }
    }

    func test_weightLog_roundTrips() throws {
        let row = WeightLogRow(id: UUID(), loggedAt: date("2026-05-22T07:00:00Z"),
                               weightLb: 305.2, source: "healthkit", isMorningWeighIn: true)
        let ck = try XCTUnwrap(WeightLogRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.loggedAt, row.loggedAt)
        XCTAssertEqual(ck.weightLb, row.weightLb, accuracy: 0.001)
        XCTAssertEqual(ck.source, row.source)
        XCTAssertEqual(ck.isMorningWeighIn, row.isMorningWeighIn)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.id, row.id)
        XCTAssertEqual(db.weightLb, row.weightLb, accuracy: 0.001)
        XCTAssertEqual(db.isMorningWeighIn, row.isMorningWeighIn)
    }

    func test_liftSession_roundTrips() throws {
        let row = LiftSessionRow(id: UUID(), sessionDate: "2026-05-20", dayLabel: "B",
                                 durationMin: 62, completed: true)
        let ck = try XCTUnwrap(LiftSessionRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.sessionDate, row.sessionDate)
        XCTAssertEqual(ck.dayLabel, row.dayLabel)
        XCTAssertEqual(ck.durationMin, row.durationMin)
        XCTAssertEqual(ck.completed, row.completed)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.sessionDate, row.sessionDate)
        XCTAssertEqual(db.completed, row.completed)
    }

    func test_liftLog_roundTrips() throws {
        let row = LiftLogRow(id: UUID(), liftSessionID: UUID(), exercise: "Squat",
                             setNumber: 3, weightLb: 225.0, reps: 5, restSec: 120)
        let ck = try XCTUnwrap(LiftLogRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.liftSessionID, row.liftSessionID)
        XCTAssertEqual(ck.exercise, row.exercise)
        XCTAssertEqual(ck.setNumber, row.setNumber)
        XCTAssertEqual(ck.weightLb, row.weightLb, accuracy: 0.001)
        XCTAssertEqual(ck.reps, row.reps)
        XCTAssertEqual(ck.restSec, row.restSec)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.liftSessionID, row.liftSessionID)
        XCTAssertEqual(db.exercise, row.exercise)
    }

    func test_swimSession_roundTrips_withNullableHR() throws {
        let row = SwimSessionRow(id: UUID(), startedAt: date("2026-05-20T06:30:00Z"),
                                 durationMin: 30, mode: "recovery", hrAvgBpm: nil, hrMaxBpm: 142)
        let ck = try XCTUnwrap(SwimSessionRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.startedAt, row.startedAt)
        XCTAssertEqual(ck.durationMin, row.durationMin)
        XCTAssertEqual(ck.mode, row.mode)
        XCTAssertNil(ck.hrAvgBpm)
        XCTAssertEqual(ck.hrMaxBpm, 142)
        let db = try grdbRoundTrip(row)
        XCTAssertNil(db.hrAvgBpm)
        XCTAssertEqual(db.hrMaxBpm, 142)
    }

    func test_walkSession_roundTrips() throws {
        let row = WalkSessionRow(id: UUID(), startedAt: date("2026-05-20T19:05:00Z"),
                                 durationMin: 20, steps: 2400, isPostMeal: true)
        let ck = try XCTUnwrap(WalkSessionRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.startedAt, row.startedAt)
        XCTAssertEqual(ck.durationMin, row.durationMin)
        XCTAssertEqual(ck.steps, row.steps)
        XCTAssertEqual(ck.isPostMeal, row.isPostMeal)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.steps, row.steps)
        XCTAssertEqual(db.isPostMeal, row.isPostMeal)
    }

    func test_urgeLog_roundTrips() throws {
        let row = UrgeLogRow(id: UUID(), loggedAt: date("2026-05-20T15:00:00Z"),
                             intensity: 7, triggersJSON: "[\"stress\",\"boredom\"]",
                             didBreathing: true, breathingCyclesCompleted: 12)
        let ck = try XCTUnwrap(UrgeLogRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.intensity, row.intensity)
        XCTAssertEqual(ck.triggersJSON, row.triggersJSON)
        XCTAssertEqual(ck.didBreathing, row.didBreathing)
        XCTAssertEqual(ck.breathingCyclesCompleted, row.breathingCyclesCompleted)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.triggersJSON, row.triggersJSON)
        XCTAssertEqual(db.breathingCyclesCompleted, row.breathingCyclesCompleted)
    }

    func test_rotation_roundTrips_withNullableRecipeURL() throws {
        let row = RotationRow(id: UUID(), weekIndex: 2, slot: 1, dishName: "Salmon coconut curry",
                              prescribedKcal: 2150, prescribedProteinG: 190, prescribedCarbsG: 210,
                              prescribedFatG: 70, recipeURL: nil)
        let ck = try XCTUnwrap(RotationRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.weekIndex, row.weekIndex)
        XCTAssertEqual(ck.slot, row.slot)
        XCTAssertEqual(ck.dishName, row.dishName)
        XCTAssertEqual(ck.prescribedKcal, row.prescribedKcal)
        XCTAssertEqual(ck.prescribedProteinG, row.prescribedProteinG)
        XCTAssertEqual(ck.prescribedCarbsG, row.prescribedCarbsG)
        XCTAssertEqual(ck.prescribedFatG, row.prescribedFatG)
        XCTAssertNil(ck.recipeURL)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.dishName, row.dishName)
        XCTAssertNil(db.recipeURL)
    }

    func test_groceryList_roundTrips() throws {
        let row = GroceryListRow(id: UUID(), shopDate: "2026-05-23", weekIndex: 2,
                                 itemsJSON: "{\"proteins\":[\"salmon\"]}", sentToReminders: false)
        let ck = try XCTUnwrap(GroceryListRow(record: row.toCKRecord()))
        XCTAssertEqual(ck.id, row.id)
        XCTAssertEqual(ck.shopDate, row.shopDate)
        XCTAssertEqual(ck.weekIndex, row.weekIndex)
        XCTAssertEqual(ck.itemsJSON, row.itemsJSON)
        XCTAssertEqual(ck.sentToReminders, row.sentToReminders)
        let db = try grdbRoundTrip(row)
        XCTAssertEqual(db.itemsJSON, row.itemsJSON)
        XCTAssertEqual(db.sentToReminders, row.sentToReminders)
    }
}
