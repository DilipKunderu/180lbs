protocol OnboardingProfileStore: AnyObject {
    func currentProfile() throws -> Profile?
    func bootstrapProfile(_ draft: ProfileDraft) throws -> Profile
}
