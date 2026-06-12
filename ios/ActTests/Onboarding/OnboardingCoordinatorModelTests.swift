import XCTest
@testable import Act

final class OnboardingCoordinatorModelTests: XCTestCase {

    private func makeModel(
        store: FakeOnboardingProfileStore = FakeOnboardingProfileStore(),
        startingAt step: OnboardingStep = .welcome,
        now: Date = Date(timeIntervalSince1970: 0)
    ) -> OnboardingCoordinatorModel {
        OnboardingCoordinatorModel(
            store: store,
            flowModel: OnboardingFlowModel(step: step),
            nowProvider: { now },
            timeZone: TimeZone(identifier: "UTC") ?? .current
        )
    }

    func test_advance_movesToNextStep() {
        let model = makeModel()

        model.advance()

        XCTAssertEqual(model.step, .profile)
    }

    func test_back_returnsToPreviousStep() {
        let model = makeModel(startingAt: .profile)

        model.back()

        XCTAssertEqual(model.step, .welcome)
    }

    func test_showsBackLink_hiddenOnWelcome_visibleAfter() {
        let model = makeModel()

        XCTAssertFalse(model.showsBackLink)
        model.advance()
        XCTAssertTrue(model.showsBackLink)
    }

    func test_advanceFromQuit_stampsQuitDateFromInjectedClock() throws {
        let isoFormatter = ISO8601DateFormatter()
        let now = try XCTUnwrap(isoFormatter.date(from: "2026-06-12T15:00:00Z"))
        let model = makeModel(startingAt: .quit, now: now)

        model.advance()

        XCTAssertEqual(model.flowModel.draftBuilder.quitDate, "2026-06-12")
        XCTAssertEqual(model.step, .rotation)
    }

    func test_advanceBeforeQuit_doesNotStampQuitDate() {
        let model = makeModel(startingAt: .welcome)

        model.advance()

        XCTAssertEqual(model.flowModel.draftBuilder.quitDate, "")
    }

    func test_completingFinalStep_bootstrapsDraft_andCallsOnFinished() throws {
        let store = FakeOnboardingProfileStore()
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-12T15:00:00Z"))
        let model = makeModel(store: store, startingAt: .quit, now: now)
        model.flowModel.draftBuilder.triggers = ["stress", "ritual"]
        model.flowModel.draftBuilder.whySentence = "I want my mornings back."
        var finished: Profile?
        model.onFinished = { finished = $0 }

        model.advance() // quit -> rotation (stamps quit date)
        model.advance() // rotation -> grocery
        model.advance() // grocery -> complete

        XCTAssertEqual(store.bootstrappedDrafts.count, 1)
        let draft = try XCTUnwrap(store.bootstrappedDrafts.first)
        XCTAssertEqual(draft.quitDate, "2026-06-12")
        XCTAssertEqual(draft.whySentence, "I want my mornings back.")
        XCTAssertEqual(draft.triggersJSON, "[\"stress\",\"ritual\"]")
        XCTAssertEqual(finished, store.profile)
        XCTAssertFalse(model.bootstrapFailed)
    }

    func test_bootstrapFailure_setsFlag_andDoesNotFinish() {
        let store = FakeOnboardingProfileStore()
        store.bootstrapError = FakeOnboardingProfileStore.StoreError()
        let model = makeModel(store: store, startingAt: .grocery)
        var finished: Profile?
        model.onFinished = { finished = $0 }

        model.advance()

        XCTAssertTrue(model.bootstrapFailed)
        XCTAssertNil(finished)
    }
}
