enum RootDestination: Equatable {
    case loading
    case onboarding
    case today

    static func resolve(profile: Profile?, readFailed: Bool) -> RootDestination {
        if readFailed {
            return .loading
        }
        return profile == nil ? .onboarding : .today
    }
}
