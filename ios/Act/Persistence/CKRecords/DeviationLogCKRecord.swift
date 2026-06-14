import CloudKit
import Foundation

extension DeviationLogRow {
    static func recordID(for id: UUID = UUID()) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: Self.recordID(for: id))
        record["meal_date"] = mealDate
        record["logged_at"] = loggedAt
        record["reason"] = reason
        if let photoURL {
            // `design.v5 §Data model`: DEVIATION_LOG.photo_url is a CKAsset on the
            // CloudKit record. Key matches the Row property / SQLite column and the
            // design field name. The local-store side keeps the URL pointer; CKAsset
            // wraps the same fileURL so callers never need to read the bytes.
            record["photo_url"] = CKAsset(fileURL: photoURL)
        }
        record["kcal_est"] = kcalEst
        record["protein_g_est"] = proteinGEst
        return record
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let id = UUID(uuidString: record.recordID.recordName),
              let mealDate = record.string(forKey: "meal_date"),
              let loggedAt = record.date(forKey: "logged_at"),
              let reason = record.string(forKey: "reason"),
              let kcalEst = record.int(forKey: "kcal_est"),
              let proteinGEst = record.int(forKey: "protein_g_est") else { return nil }
        let photoURL = (record["photo_url"] as? CKAsset)?.fileURL
        self.init(
            id: id,
            mealDate: mealDate,
            loggedAt: loggedAt,
            reason: reason,
            photoURL: photoURL,
            kcalEst: kcalEst,
            proteinGEst: proteinGEst
        )
    }
}
