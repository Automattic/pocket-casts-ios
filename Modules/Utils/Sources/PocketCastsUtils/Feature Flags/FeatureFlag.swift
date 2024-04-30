import Foundation

public enum FeatureFlag: String, CaseIterable {
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

    /// Enable chapters to be loaded from the RSS feed
    case rssChapters

    /// Enable a quicker and more responsive player transition
    case newPlayerTransition

    /// Avoid logging out user on non-authorization HTTP errors
    case errorLogoutHandling

    /// Enable the ability to rate podcasts
    case giveRatings

    /// Enable selecting/deselecting episode chapters
    case deselectChapters

    /// Store settings as JSON in User Defaults (global) or SQLite (podcast)
    case newSettingsStorage

    /// Syncing all app and podcast settings
    case settingsSync

    /// Show the modal about the partnership with Slumber Studios
    case slumber

    /// Enable the new flow for Account upgrade prompt where it start IAP flow directly from account cell
    case newAccountUpgradePromptFlow

    case cachePlayingEpisode

    case categoriesRedesign

    /// show UpNext tab on the main tab bar
    case upNextOnTabBar

    /// Enhances the profile view to display more fields from the user's Gravatar profile.
    case displayGravatarProfile
    
    public var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        return `default`
    }

    public var `default`: Bool {
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
        case .rssChapters:
            false // To be enabled, newShowNotesEndpoint needs to be too
        case .newPlayerTransition:
            true
        case .errorLogoutHandling:
            false
        case .giveRatings:
            false
        case .deselectChapters:
            false
        case .newSettingsStorage:
            shouldEnableSyncedSettings
        case .settingsSync:
            shouldEnableSyncedSettings
        case .slumber:
            false
        case .newAccountUpgradePromptFlow:
            false
        case .cachePlayingEpisode:
            true
        case .categoriesRedesign:
            true
        case .upNextOnTabBar:
            true
        case .displayGravatarProfile:
            false
        }
    }

    private var shouldEnableSyncedSettings: Bool {
        false
    }

    /// Remote Feature Flag
    /// This should match a Firebase Remote Config Parameter name (key)
    public var remoteKey: String? {
        switch self {
        case .deselectChapters:
            "deselect_chapters_enabled"
        case .newAccountUpgradePromptFlow:
            "new_account_upgrade_prompt_flow"
        case .cachePlayingEpisode:
            "cache_playing_episode"
        case .newSettingsStorage:
            shouldEnableSyncedSettings ? "new_settings_storage" : nil
        case .settingsSync:
            shouldEnableSyncedSettings ? "settings_sync" : nil
        case .newShowNotesEndpoint:
            "new_show_notes"
        case .episodeFeedArtwork:
            "episode_artwork"
        case .rssChapters:
            "rss_chapters"
        default:
            nil
        }
    }
}

extension FeatureFlag: OverrideableFlag {
    public var description: String {
        rawValue
    }

    public var canOverride: Bool {
        true
    }

    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
}
