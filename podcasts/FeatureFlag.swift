import Foundation

enum FeatureFlag: String, CaseIterable {
    /// Whether we should detect and show the free trial UI
    case freeTrialsEnabled

    /// Whether the Tracks analytics are enabled
    case tracksEnabled

    /// Whether logging of Tracks events in console are enabled
    case tracksLoggingEnabled

    /// Whether logging of Firebase events in console are enabled
    case firebaseLoggingEnabled

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Adds the Sign In With Apple options to the login flow
    case signInWithApple

    /// Displays the new onboarding view updates
    case onboardingUpdates

    var isEnabled: Bool {
        switch self {
        case .freeTrialsEnabled:
            return true
        case .tracksEnabled:
            return true
        case .tracksLoggingEnabled:
            return false
        case .firebaseLoggingEnabled:
            return false
        case .endOfYear:
            return true
        case .signInWithApple:
            return false
        case .onboardingUpdates:
            return true
        }
    }
}
