import GRDB

extension LocalStore: OnboardingProfileStore {
    /// Reads the singleton PROFILE row off the GRDB read path (no write
    /// transaction) and maps it to the `Profile` projection, returning `nil`
    /// when onboarding has not yet bootstrapped a profile.
    func currentProfile() throws -> Profile? {
        try databaseWriter.read { db in
            try ProfileRow.fetchOne(db).map(Profile.init(from:))
        }
    }
}
