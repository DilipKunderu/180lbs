import Foundation
@testable import Act

/// In-memory `OnboardingProfileStore` for coordinator/root model tests —
/// no GRDB, no disk. Configure `currentProfileError` / `bootstrapError`
/// to exercise failure paths.
final class FakeOnboardingProfileStore: OnboardingProfileStore {
    struct StoreError: Error {}

    var profile: Profile?
    var currentProfileError: Error?
    var bootstrapError: Error?
    private(set) var bootstrappedDrafts: [ProfileDraft] = []

    func currentProfile() throws -> Profile? {
        if let currentProfileError {
            throw currentProfileError
        }
        return profile
    }

    func bootstrapProfile(_ draft: ProfileDraft) throws -> Profile {
        if let bootstrapError {
            throw bootstrapError
        }
        bootstrappedDrafts.append(draft)
        let bootstrapped = Self.makeProfile(quitDate: draft.quitDate)
        profile = bootstrapped
        return bootstrapped
    }

    static func makeProfile(quitDate: String = "2026-06-12") -> Profile {
        Profile(from: ProfileRow(
            recordName: ProfileRow.singletonRecordName,
            heightIn: 72,
            sex: "M",
            age: 33,
            startWeightLb: 310,
            goalWeightLb: 180,
            wakeTime: "05:00",
            mealWindowStart: "18:00",
            mealWindowEnd: "19:00",
            bedTime: "21:30",
            kcalTarget: 2150,
            proteinTargetG: 190,
            quitDate: quitDate,
            whySentence: "",
            triggersJSON: "[]",
            cleanStreakDays: 0,
            currentWeightLbCached: 310,
            adherencePctCached: 0
        ))
    }
}
