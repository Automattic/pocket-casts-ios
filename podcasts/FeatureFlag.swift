import Foundation

enum FeatureFlag: String, CaseIterable {
    /// Whether we should detect and show the free trial UI
    case freeTrialsEnabled

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

    /// New episodes autoplay if Up Next is empty
    case autoplay

    /// Enable the new show notes endpoint plus embedded episode artwork
    case newShowNotesEndpoint

    /// Enable retrieving episode artwork from the RSS feed
    case episodeFeedArtwork

    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .freeTrialsEnabled:
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
            return true
        case .showRatings:
            return true
        case .autoplay:
            return true
        case .newShowNotesEndpoint:
            return false
        case .episodeFeedArtwork:
            return false // To be enabled, newShowNotesEndpoint needs to be too
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

    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
}
