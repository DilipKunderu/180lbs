struct ProfileDraftBuilder {
    var triggers: [String] = []
    var whySentence = ""
    var quitDate = ""

    func build() -> ProfileDraft {
        ProfileDraft(
            heightIn: 0,
            sex: "",
            age: 0,
            startWeightLb: 0,
            goalWeightLb: 0,
            wakeTime: "",
            mealWindowStart: "",
            mealWindowEnd: "",
            bedTime: "",
            kcalTarget: 0,
            proteinTargetG: 0,
            quitDate: "",
            whySentence: "",
            triggersJSON: ""
        )
    }
}
