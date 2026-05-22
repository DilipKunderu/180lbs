import CloudKit
import Foundation

extension UrgeLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["logged_at"] = loggedAt
        record["intensity"] = intensity
        record["triggers"] = triggersJSON
        record["did_breathing"] = didBreathing
        record["breathing_cycles_completed"] = breathingCyclesCompleted
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let loggedAt = record.date(forKey: "logged_at"),
              let intensity = record.int(forKey: "intensity"),
              let triggersJSON = record.string(forKey: "triggers"),
              let didBreathing = record.bool(forKey: "did_breathing"),
              let breathingCyclesCompleted = record.int(forKey: "breathing_cycles_completed") else { return nil }
        self.init(id: id, loggedAt: loggedAt, intensity: intensity, triggersJSON: triggersJSON, didBreathing: didBreathing, breathingCyclesCompleted: breathingCyclesCompleted)
    }
}
