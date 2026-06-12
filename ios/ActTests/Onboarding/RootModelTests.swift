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
}
