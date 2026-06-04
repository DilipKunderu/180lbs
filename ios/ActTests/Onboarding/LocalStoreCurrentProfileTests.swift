import GRDB
import XCTest
@testable import Act

final class LocalStoreCurrentProfileTests: XCTestCase {
    func test_currentProfile_returnsNil_whenNoProfileExists() throws {
        let store = try LocalStore(database: DatabaseQueue())

        let profile = try store.currentProfile()

        XCTAssertNil(profile)
    }

    func test_currentProfile_returnsProfile_afterBootstrap() throws {
        let store = try LocalStore(database: DatabaseQueue())
        let bootstrapped = try store.bootstrapProfile(
            LocalStoreTestSupport.makeDraft(quitDate: "2026-05-22")
        )

        let profile = try XCTUnwrap(store.currentProfile())

        XCTAssertEqual(profile, bootstrapped)
    }
}
