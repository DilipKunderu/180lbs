import Foundation

struct ProfileDraftBuilder {
    var triggers: [String] = []
    var whySentence = ""
    var quitDate = ""

    func build() -> ProfileDraft {
        ProfileDraft(
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
            whySentence: whySentence,
            triggersJSON: serializedTriggers()
        )
    }

    /// Serializes `triggers` to a compact JSON array string (no whitespace),
    /// e.g. `["stress","boredom"]`; an empty list yields `"[]"`.
    private func serializedTriggers() -> String {
        guard let data = try? JSONEncoder().encode(triggers),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
