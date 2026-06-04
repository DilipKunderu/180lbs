import XCTest
@testable import Act

final class RootDestinationTests: XCTestCase {
    func test_resolve_withProfile_isToday() {
        let profile = Profile(from: LocalStoreTestSupport.makeProfile())

        let destination = RootDestination.resolve(profile: profile, readFailed: false)

        XCTAssertEqual(destination, .today)
    }

    func test_resolve_withNilProfile_isOnboarding() {
        let destination = RootDestination.resolve(profile: nil, readFailed: false)

        XCTAssertEqual(destination, .onboarding)
    }

    func test_resolve_withReadFailure_isLoading_neverOnboarding() {
        let profile = Profile(from: LocalStoreTestSupport.makeProfile())

        let destination = RootDestination.resolve(profile: profile, readFailed: true)

        XCTAssertEqual(destination, .loading)
    }
}
