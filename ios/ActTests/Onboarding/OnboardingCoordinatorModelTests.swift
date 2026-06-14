import XCTest
@testable import Act

final class OnboardingCoordinatorModelTests: XCTestCase {

    private func makeModel(
        store: FakeOnboardingProfileStore = FakeOnboardingProfileStore(),
        startingAt step: OnboardingStep = .welcome,
        now: Date = Date(timeIntervalSince1970: 0),
        authorizer: (any HealthAuthorizationRequesting)? = nil,
        notificationAuthorizer: (any NotificationAuthorizationRequesting)? = nil
    ) -> OnboardingCoordinatorModel {
        OnboardingCoordinatorModel(
            store: store,
            flowModel: OnboardingFlowModel(step: step),
            nowProvider: { now },
            timeZone: TimeZone(identifier: "UTC") ?? .current,
            healthAuthorizer: authorizer,
            notificationAuthorizer: notificationAuthorizer
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

    // MARK: - HealthKit authorization seam

    /// Advancing off `.health` must (a) move the step forward immediately
    /// (synchronously, before any async auth work) and (b) fire exactly one
    /// `requestAuthorization()` call through the injected seam.
    /// Awaiting `healthAuthorizationTask` drains the async work so the count
    /// assertion is deterministic even in a fast-executor environment.
    func test_advanceFromHealth_advancesImmediately_andRequestsHealthAuthorizationOnce() async {
        let spy = SpyHealthAuthorizer()
        let model = makeModel(startingAt: .health, authorizer: spy)

        model.advance()

        // Step advances synchronously — no await needed.
        XCTAssertEqual(model.step, .notifications)
        // Task handle must be retained immediately (before the async work completes).
        XCTAssertNotNil(model.healthAuthorizationTask,
                        "expected a retained task handle after advancing from .health")

        // Drain the fire-and-forget task before checking the call count.
        await model.healthAuthorizationTask?.value

        XCTAssertEqual(spy.requestCount, 1)
    }

    /// If the authorizer throws, the flow must still have advanced and the
    /// error must be swallowed (no `bootstrapFailed` flag, no crash).
    func test_advanceFromHealth_whenAuthorizationThrows_stillAdvances() async {
        let spy = SpyHealthAuthorizer()
        spy.thrownError = NSError(domain: "test", code: 1)
        let model = makeModel(startingAt: .health, authorizer: spy)

        model.advance()

        XCTAssertEqual(model.step, .notifications)
        // Task handle must be retained even when the authorizer will throw.
        XCTAssertNotNil(model.healthAuthorizationTask,
                        "expected a retained task handle after advancing from .health")

        await model.healthAuthorizationTask?.value

        XCTAssertEqual(spy.requestCount, 1)
        XCTAssertFalse(model.bootstrapFailed)
    }

    /// When no authorizer is injected (`nil` = the `-ActSkipHealthKitAuthorization` /
    /// no-op path), advancing from `.health` must not crash and must leave
    /// `healthAuthorizationTask` as `nil` (nothing to wait on).
    func test_advanceFromHealth_withNilAuthorizer_doesNotCrashAndLeavesTaskNil() {
        let model = makeModel(startingAt: .health, authorizer: nil)

        model.advance()

        XCTAssertEqual(model.step, .notifications)
        XCTAssertNil(model.healthAuthorizationTask,
                     "expected no task when authorizer is nil")
    }

    /// No step other than `.health` must trigger a health-authorization request.
    /// The task handle must remain `nil` for every other transition.
    func test_advanceFromOtherSteps_doesNotRequestHealthAuthorization() async {
        // `.grocery` is intentionally included: FakeOnboardingProfileStore bootstraps
        // successfully by default, so advancing from .grocery completes onboarding without
        // crashing, giving us a valid signal that no auth task is spawned there either.
        let nonHealthSteps = OnboardingStep.allCases.filter { $0 != .health }
        for step in nonHealthSteps {
            let spy = SpyHealthAuthorizer()
            let model = makeModel(startingAt: step, authorizer: spy)

            model.advance()

            // No task should be spawned.
            XCTAssertNil(model.healthAuthorizationTask,
                         "expected no auth task when advancing from .\(step)")
            XCTAssertEqual(spy.requestCount, 0,
                           "expected zero auth requests when advancing from .\(step)")
        }
    }

    // MARK: - Notification authorization seam (GAP-ONB-1)

    /// Advancing off `.notifications` must (a) move the step forward immediately
    /// and (b) fire exactly one `requestAuthorization()` through the injected
    /// notification seam (the system permission sheet; registration stays
    /// deferred per design.v5 §Flow 4).
    func test_advanceFromNotifications_advancesImmediately_andRequestsNotificationAuthorizationOnce() async {
        let spy = SpyNotificationAuthorizer()
        let model = makeModel(startingAt: .notifications, notificationAuthorizer: spy)

        model.advance()

        XCTAssertEqual(model.step, .scale)
        XCTAssertNotNil(model.notificationAuthorizationTask,
                        "expected a retained task handle after advancing from .notifications")

        await model.notificationAuthorizationTask?.value

        XCTAssertEqual(spy.requestCount, 1)
    }

    /// A denial / thrown error must be swallowed: the flow still advances.
    func test_advanceFromNotifications_whenAuthorizationThrows_stillAdvances() async {
        let spy = SpyNotificationAuthorizer()
        spy.thrownError = NSError(domain: "test", code: 1)
        let model = makeModel(startingAt: .notifications, notificationAuthorizer: spy)

        model.advance()

        XCTAssertEqual(model.step, .scale)
        XCTAssertNotNil(model.notificationAuthorizationTask)

        await model.notificationAuthorizationTask?.value

        XCTAssertEqual(spy.requestCount, 1)
        XCTAssertFalse(model.bootstrapFailed)
    }

    /// No authorizer injected (UI-test / no-op path): advancing must not crash
    /// and must leave `notificationAuthorizationTask` nil.
    func test_advanceFromNotifications_withNilAuthorizer_doesNotCrashAndLeavesTaskNil() {
        let model = makeModel(startingAt: .notifications, notificationAuthorizer: nil)

        model.advance()

        XCTAssertEqual(model.step, .scale)
        XCTAssertNil(model.notificationAuthorizationTask)
    }

    /// No step other than `.notifications` triggers a notification-auth request.
    func test_advanceFromOtherSteps_doesNotRequestNotificationAuthorization() {
        let otherSteps = OnboardingStep.allCases.filter { $0 != .notifications }
        for step in otherSteps {
            let spy = SpyNotificationAuthorizer()
            let model = makeModel(startingAt: step, notificationAuthorizer: spy)

            model.advance()

            XCTAssertNil(model.notificationAuthorizationTask,
                         "expected no notification-auth task when advancing from .\(step)")
            XCTAssertEqual(spy.requestCount, 0,
                           "expected zero notification-auth requests when advancing from .\(step)")
        }
    }
}
