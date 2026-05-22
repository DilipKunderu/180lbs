import CloudKit
import Foundation

extension LiftLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["lift_session_id"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: liftSessionID.uuidString), action: .deleteSelf)
        record["exercise"] = exercise
        record["set_number"] = setNumber
        record["weight_lb"] = weightLb
        record["reps"] = reps
        record["rest_sec"] = restSec
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let reference = record["lift_session_id"] as? CKRecord.Reference,
              let liftSessionID = UUID(uuidString: reference.recordID.recordName),
              let exercise = record.string(forKey: "exercise"),
              let setNumber = record.int(forKey: "set_number"),
              let weightLb = record.double(forKey: "weight_lb"),
              let reps = record.int(forKey: "reps"),
              let restSec = record.int(forKey: "rest_sec") else { return nil }
        self.init(id: id, liftSessionID: liftSessionID, exercise: exercise, setNumber: setNumber, weightLb: weightLb, reps: reps, restSec: restSec)
    }
}
