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
