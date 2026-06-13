import Foundation
@testable import Act

/// Lock-guarded `@unchecked Sendable` spy for `NotificationAuthorizationRequesting`.
///
/// Records the number of times `requestAuthorization()` is called.
/// Configure `thrownError` before the call to simulate a failure / denial path.
final class SpyNotificationAuthorizer: NotificationAuthorizationRequesting, @unchecked Sendable {
    // @unchecked Sendable: all mutable state is serialised on the lock below.
    private let lock = NSLock()
    private var _requestCount = 0
    private var _thrownError: Error?

    /// The number of `requestAuthorization()` invocations received.
    var requestCount: Int { lock.withLock { _requestCount } }

    /// Set before the call under test to have the spy throw on every
    /// subsequent `requestAuthorization()` call.
    var thrownError: Error? {
        get { lock.withLock { _thrownError } }
        set { lock.withLock { _thrownError = newValue } }
    }

    func requestAuthorization() async throws {
        let errorToThrow: Error? = lock.withLock {
            _requestCount += 1
            return _thrownError
        }
        if let errorToThrow {
            throw errorToThrow
        }
    }
}
