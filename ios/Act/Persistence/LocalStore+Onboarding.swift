import Foundation

extension LocalStore: OnboardingProfileStore {
    func currentProfile() throws -> Profile? {
        throw CocoaError(.coderInvalidValue)
    }
}
