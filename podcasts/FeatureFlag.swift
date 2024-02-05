import Foundation

enum FeatureFlag: String, CaseIterable {
    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Enable the new show notes endpoint plus embedded episode artwork
    case newShowNotesEndpoint

    /// Enable retrieving episode artwork from the RSS feed
    case episodeFeedArtwork

    /// Enable a quicker and more responsive player transition
    case newPlayerTransition

    /// Avoid logging out user on non-authorization HTTP errors
    case errorLogoutHandling

    /// Enable the ability to rate podcasts
    case giveRatings

    /// Syncing all app and podcast settings
    case settingsSync

    /// Enable the new flow for Account upgrade prompt where it start IAP flow directly from account cell
    case newAccountUpgradePromptFlow

    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        return `default`
    }

    var `default`: Bool {
        switch self {
        case .tracksLogging:
            false
        case .firebaseLogging:
            false
        case .endOfYear:
            false
        case .newShowNotesEndpoint:
            false
        case .episodeFeedArtwork:
            false // To be enabled, newShowNotesEndpoint needs to be too
        case .newPlayerTransition:
            true
        case .errorLogoutHandling:
            false
        case .giveRatings:
            false
        case .settingsSync:
            false
        case .newAccountUpgradePromptFlow:
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
