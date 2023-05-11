import Foundation

enum FeatureFlag: String, CaseIterable {
    /// Whether we should detect and show the free trial UI
    case freeTrialsEnabled

    /// Whether the Tracks analytics are enabled
    case tracks

    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Adds the Sign In With Apple options to the login flow
    case signInWithApple

    /// Displays the new onboarding view updates
    case onboardingUpdates

    /// New search
    case newSearch

    /// Bookmarks / Highlights
    case bookmarks

    /// Auto scrolls Discover Featured carousel
    case discoverFeaturedAutoScroll

    /// Patron
    case patron

    /// Displaying podcast ratings
    case showRatings

    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .freeTrialsEnabled:
            return true
        case .tracks:
            return true
        case .tracksLogging:
            return false
        case .firebaseLogging:
            return false
        case .endOfYear:
            return false
        case .signInWithApple:
            return true
        case .onboardingUpdates:
            return true
        case .newSearch:
            return true
        case .bookmarks:
            return false
        case .discoverFeaturedAutoScroll:
            return true
        case .patron:
            return false
        case .showRatings:
            return true
        }
    }
}

extension FeatureFlag: OverrideableFlag {
    var description: String {
        rawValue
    }

    var canOverride: Bool {
        true
    }
}
