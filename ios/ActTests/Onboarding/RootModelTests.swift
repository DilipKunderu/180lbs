import XCTest
@testable import Act

final class RootModelTests: XCTestCase {

    func test_load_withNoProfile_routesToOnboarding() {
        let model = RootModel(store: FakeOnboardingProfileStore())

        model.load()

        XCTAssertEqual(model.destination, .onboarding)
    }

    func test_load_withExistingProfile_routesToToday() {
        let store = FakeOnboardingProfileStore()
        store.profile = FakeOnboardingProfileStore.makeProfile()
        let model = RootModel(store: store)

        model.load()

        XCTAssertEqual(model.destination, .today)
    }

    func test_load_whenReadThrows_staysOnLoading() {
        let store = FakeOnboardingProfileStore()
        store.currentProfileError = FakeOnboardingProfileStore.StoreError()
        let model = RootModel(store: store)

        model.load()

        XCTAssertEqual(model.destination, .loading)
    }

    func test_load_withNilStore_staysOnLoading() {
        let model = RootModel(store: nil)

        model.load()

        XCTAssertEqual(model.destination, .loading)
        XCTAssertNil(model.onboardingModel)
    }

    func test_onboardingFinished_routesToToday() {
        let model = RootModel(store: FakeOnboardingProfileStore())
        model.load()

        model.onboardingFinished(FakeOnboardingProfileStore.makeProfile())

        XCTAssertEqual(model.destination, .today)
    }

    func test_completingOnboardingViaCoordinator_routesToToday() {
        let model = RootModel(store: FakeOnboardingProfileStore())
        model.load()
        guard let onboarding = model.onboardingModel else {
            return XCTFail("expected onboarding model when a store exists")
        }

        for _ in OnboardingStep.allCases {
            onboarding.advance()
        }

        XCTAssertEqual(model.destination, .today)
    }

    // MARK: - Today model wiring

    /// Verifies that when `RootModel` is constructed with all three Today seams and resolves to
    /// `.today` (store already has a profile), `todayModel` is non-nil. This is the RED driver
    /// for sub-task 7; it will fail until `RootModel` gains a `todayModel` property and the
    /// Today-seam init parameters.
    func test_todayModel_isNonNil_whenStoreAndTodaySeanmsAreProvided_andResolvesToToday() throws {
        let store = FakeOnboardingProfileStore()
        store.profile = FakeOnboardingProfileStore.makeProfile()

        let nowAfterWake = try XCTUnwrap(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(year: 2026, month: 6, day: 13, hour: 9, minute: 0)
            ),
            "gregorian calendar must produce a date from valid components"
        )
        let facts = TodayFacts(
            now: nowAfterWake,
            wakeTime: DateComponents(hour: 5, minute: 0),
            mealWindowStart: DateComponents(hour: 18, minute: 0),
            bedTime: DateComponents(hour: 21, minute: 30),
            weighInLogged: false
        )
        let reader = FakeTodayFactsReader(facts: facts)
        let writer = WeightLogWritingSpy()
        let bodyMass = FakeBodyMassReader(stubbedValue: nil)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "America/New_York"),
            "America/New_York must be a valid TimeZone identifier"
        )

        let model = RootModel(
            store: store,
            todayReader: reader,
            todayWriter: writer,
            bodyMass: bodyMass,
            calendar: calendar
        )
        model.load()

        XCTAssertEqual(model.destination, .today)
        XCTAssertNotNil(model.todayModel, "todayModel must be non-nil when all Today seams are injected and destination resolves to .today")
    }

    // MARK: - Health authorization wiring

    func test_onboardingModel_requestsHealthAuthorization_throughInjectedAuthorizer() async throws {
        let spy = SpyHealthAuthorizer()
        let model = RootModel(store: FakeOnboardingProfileStore(), healthAuthorizer: spy)
        model.load()
        let onboarding = try XCTUnwrap(
            model.onboardingModel,
            "expected an OnboardingCoordinatorModel when a store is provided"
        )

        // Advance welcome → profile → health (2 advances), then off .health (1 more).
        // Step order: welcome(0), profile(1), health(2), notifications(3), …
        onboarding.advance() // welcome → profile
        onboarding.advance() // profile → health
        onboarding.advance() // health → notifications; fires the authorization task

        await onboarding.healthAuthorizationTask?.value

        XCTAssertEqual(spy.requestCount, 1, "authorization must be requested exactly once when leaving .health")
    }
}
