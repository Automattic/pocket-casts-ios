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

    /// New episodes autoplay if Up Next is empty
    case autoplay

    /// Enable the new show notes endpoint plus embedded episode artwork
    case newShowNotesEndpoint

    /// Enable retrieving episode artwork from the RSS feed
    case episodeFeedArtwork

    /// Enable the ability to rate podcasts
    case giveRatings

    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        return `default`
    }

    var `default`: Bool {
        switch self {
        case .freeTrialsEnabled:
            true
        case .tracks:
            true
        case .tracksLogging:
            false
        case .firebaseLogging:
            false
        case .endOfYear:
            false
        case .signInWithApple:
            true
        case .onboardingUpdates:
            true
        case .newSearch:
            true
        case .bookmarks:
            false
        case .discoverFeaturedAutoScroll:
            true
        case .patron:
            true
        case .showRatings:
            true
        case .autoplay:
            true
        case .newShowNotesEndpoint:
            true
        case .episodeFeedArtwork:
            Self.isTestFlight ? true : false
        case .giveRatings:
            false
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
