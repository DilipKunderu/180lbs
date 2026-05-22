import CloudKit
import Foundation

extension SwimSessionRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString) }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["started_at"] = startedAt
        record["duration_min"] = durationMin
        record["mode"] = mode
        record["hr_avg_bpm"] = hrAvgBpm
        record["hr_max_bpm"] = hrMaxBpm
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let startedAt = record.date(forKey: "started_at"),
              let durationMin = record.int(forKey: "duration_min"),
              let mode = record.string(forKey: "mode") else { return nil }
        self.init(id: id, startedAt: startedAt, durationMin: durationMin, mode: mode, hrAvgBpm: record.int(forKey: "hr_avg_bpm"), hrMaxBpm: record.int(forKey: "hr_max_bpm"))
    }
}
