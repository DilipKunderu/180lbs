import XCTest
@testable import Act

final class ProfileDraftBuilderTests: XCTestCase {
    func test_build_withDefaults_matchesSeed() {
        let draft = ProfileDraftBuilder().build()

        XCTAssertEqual(draft.heightIn, 72)
        XCTAssertEqual(draft.sex, "M")
        XCTAssertEqual(draft.age, 33)
        XCTAssertEqual(draft.startWeightLb, 310)
        XCTAssertEqual(draft.goalWeightLb, 180)
        XCTAssertEqual(draft.wakeTime, "05:00")
        XCTAssertEqual(draft.mealWindowStart, "18:00")
        XCTAssertEqual(draft.mealWindowEnd, "19:00")
        XCTAssertEqual(draft.bedTime, "21:30")
        XCTAssertEqual(draft.kcalTarget, 2150)
        XCTAssertEqual(draft.proteinTargetG, 190)
        XCTAssertEqual(draft.quitDate, "")
        XCTAssertEqual(draft.whySentence, "")
        XCTAssertEqual(draft.triggersJSON, "[]")
    }

    func test_setTriggers_serializesToTriggersJSON() {
        var builder = ProfileDraftBuilder()
        builder.triggers = ["stress", "boredom"]

        let draft = builder.build()

        XCTAssertEqual(draft.triggersJSON, "[\"stress\",\"boredom\"]")
    }

    func test_setWhySentence_updatesBuild() {
        var builder = ProfileDraftBuilder()
        builder.whySentence = "I want my mornings back."

        let draft = builder.build()

        XCTAssertEqual(draft.whySentence, "I want my mornings back.")
    }
}
