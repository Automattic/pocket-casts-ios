import Foundation

public enum FeatureFlag: String, CaseIterable {
    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Enable show notes using the new endpoint
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

    /// When enabled it updates the code on filter callback to use a safer method to convert unmanaged player references
    /// This is to fix this: https://a8c.sentry.io/share/issue/39a6d2958b674ec3b7a4d9248b4b5ffa/
    case defaultPlayerFilterCallbackFix

    case downloadFixes

    /// When a user sign in, we always mark ALL podcasts as unsynced
    /// This recently caused issues, syncing changes that shouldn't have been synced
    /// When `true`, we only mark podcasts as unsynced if the user never signed in before
    case onlyMarkPodcastsUnsyncedForNewUsers

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
            false
        case .rssChapters:
            false
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
        case .defaultPlayerFilterCallbackFix:
            true
        case .upNextOnTabBar:
            true
        case .downloadFixes:
            true
        case .onlyMarkPodcastsUnsyncedForNewUsers:
            true
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
        case .categoriesRedesign:
            "categories_redesign"
        case .defaultPlayerFilterCallbackFix:
            "default_player_filter_callback_fix"
        case .upNextOnTabBar:
            "up_next_on_tab_bar"
        default:
            rawValue.lowerSnakeCased()
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
