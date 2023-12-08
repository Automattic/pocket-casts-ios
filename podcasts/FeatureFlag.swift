import Foundation

enum FeatureFlag: String, CaseIterable {
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

    /// Bookmarks / Highlights
    case bookmarks

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

    /// Enable a quicker and more responsive player transition
    case newPlayerTransition

    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .tracksLogging:
            return false
        case .firebaseLogging:
            return false
        case .endOfYear:
            return true
        case .signInWithApple:
            return true
        case .onboardingUpdates:
            return true
        case .bookmarks:
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
        case .newPlayerTransition:
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

    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
}
