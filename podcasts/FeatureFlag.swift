import Foundation

enum FeatureFlag: String, CaseIterable {
    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Bookmarks / Highlights
    case bookmarks

    /// Patron
    case patron

    /// Displaying podcast ratings
    case showRatings

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
        case .bookmarks:
            return true
        case .patron:
            return true
        case .showRatings:
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
