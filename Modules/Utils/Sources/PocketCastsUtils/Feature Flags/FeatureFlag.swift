import Foundation

public enum FeatureFlag: String, CaseIterable {

    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging the theme properties in the Tracks events
    case appThemePropertiesLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Avoid logging out user on non-authorization HTTP errors
    case errorLogoutHandling

    /// Store settings as JSON in User Defaults (global) or SQLite (podcast)
    case newSettingsStorage

    /// Syncing all app and podcast settings
    case settingsSync

    /// Show the modal about the partnership with Slumber Studios
    case slumber

    /// Enable the new flow for Account upgrade prompt where it start IAP flow directly from account cell
    case newAccountUpgradePromptFlow

    /// Enable the AVExportSession parallel download of any playing episode
    case streamAndCachePlayingEpisode

    /// When enabled it updates the code on filter callback to use a safer method to convert unmanaged player references
    /// This is to fix this: https://a8c.sentry.io/share/issue/39a6d2958b674ec3b7a4d9248b4b5ffa/
    case defaultPlayerFilterCallbackFix

    case downloadFixes

    /// When a user sign in, we always mark ALL podcasts as unsynced
    /// This recently caused issues, syncing changes that shouldn't have been synced
    /// When `true`, we only mark podcasts as unsynced if the user never signed in before
    case onlyMarkPodcastsUnsyncedForNewUsers

    /// Only update an episode if it fails playing
    /// If set to `false`, it will use the previous mechanism that always update
    /// but can lead to a bigger time between tapping play and actually playing it
    case whenPlayingOnlyUpdateEpisodeIfPlaybackFails

    /// Use the Accelerate framework to speed up custom effects
    case accelerateEffects

    /// Enables the Kids banner
    case kidsProfile

    /// Enable the new Upgrade Experiments
    case upgradeExperiment

    /// When enabled, we ignore audio interruptions with InterruptionReason set to routeDisconnected
    /// (introduced in iOS 17 and watchOS 10) because these are not really interruptions as we have
    /// implemented them previously. If the route is disconnected, audio stops indefinitely
    /// until a new route connects (for which we'll received a different notification and handle accordingly)
    /// See: https://github.com/Automattic/pocket-casts-ios/issues/2049
    case ignoreRouteDisconnectedInterruption

    /// Enable the Referrals feature
    case referrals

    /// Enables the referrals Send Flow
    case referralsSend

    /// Enables the referrals Claim Flow
    case referralsClaim

    /// When accessing Stats, it checks if the local stats are behind remote
    /// If it is, it updates it
    /// This is meant to fix an issue for users that were losing stats
    case syncStats

    /// Uses the `isReadyToPlay` function to decide what logic to use when skipping.
    /// There's some scenario when the Default player switched to the Effects player when the stream is paused.
    /// This makes the skip unusable as the player doesn't have its task set yet.
    /// If the player is not ready to play, we should use the same logic we use when the player doesn't exist yet.
    case playerIsReadyToPlay

    // Shows the searchbar in Listening History view
    case listeningHistorySearch

    /// Use the Mimetype library to check the file mimetype
    case useMimetypePackage

    /// Enable the Segmented Control into the Effects Player panel
    /// to apply the Global or local settings
    case customPlaybackSettings

    /// Run a vacuum process on the database in order to optimize data fetch
    case runVacuumOnVersionUpdate

    /// Enable the End of Year 2024 recap
    case endOfYear2024

    /// Enable the Up Next shuffle button
    case upNextShuffle

    /// Push two auto downloads on subscribe of a podcast
    case autoDownloadOnSubscribe

    /// Replace Subscribe/Unsubscribe with Follow/Unfollow
    case useFollowNaming

    /// Use a cookie to manage `MTAudioProcessingTap` deallocation
    case useDefaultPlayerTapCookie

    /// Use single update query to mark all episodes selected synced
    case markAllSyncedInSingleStatement

    /// Enable the winback screen and flow
    case winback

    /// Show Manage Downloaded episode banner/modal when running in low space in the device
    case manageDownloadedEpisodes

    /// Uses the episode IDs from the server's response rather than our local database IDs
    case useSyncResponseEpisodeIDs

    /// Disables logout / keychain clearing when errors occur in the background
    case avoidLogoutInBackground

    case disablePrivateFeedSharing

    /// Enable/Disable the podcast feed reload feature
    case podcastFeedUpdate

    /// Enable/Disable the use of a thread safe ongoing downloads cache
    case downloadsThreadSafeCache

    /// Enable Disable the use of suggested folders
    case suggestedFolders

    /// Enable the generated transcript
    case generatedTranscripts

    /// Encourage Account Creation
    case encourageAccountCreation

    /// Enable Libro.fm icons in Paywall
    case libroFm

    /// Any time watch data is sent, we refresh the watch logs and save them to a file for sending to Zendesk or exporting
    case refreshAndSaveWatchLogsOnSend

    /// Avoid replace actions for Up Next episode queue when swapping the currently playing episode
    case avoidReplaceOnEpisodeSwap

    /// Enable the new podcast sorting options
    case podcastsSortChanges

    /// Recommendations including discover v3 support
    case recommendations

    /// Cancel Subscription Survey
    case cancelSubscriptionSurvey

    /// Ignore server IAP check
    case newOfferEligibilityCheck

    /// When replacing an episode list with a new one, use the provided episode instead of Up Next Queue
    case replaceSpecificEpisode

    /// Shows transcript excerpt in episode detail
    case episodeDetailTranscript

    /// Include banner ad atop the podcasts list. This is fetched from ths server so can be disabled from there as well.
    case bannerAdPodcasts

    /// Include the banner ad atop the player screen. This is fetched from ths server so can be disabled from there as well.
    case bannerAdPlayer

    /// Improves configuration for the streaming requet download session
    case streamingCustomSessionConfiguration

    /// Guest List and Network Highligh Redesign
    case guestListsNetworkHighlightsRedesign

    /// Adds Discover category user recommendations
    case smartCategories

    /// Enabled the attributed text view in the Data Usage warning Sheet
    case useDescriptiveActionAttributedTextView

    /// Use the new upgrade screens
    case newOnboardingUpgrade

    /// Use the new upgrade screens with Variant B timeline before features
    case newOnboardingVariant

    /// Enable the new playlists rebranding
    case playlistsRebranding

    /// Retry failed downloads and stream without the user agent
    case retryWithoutUserAgent

    /// Show a satisfaction survey before prompting to rate
    case userSatisfactionSurvey

    /// Whether to use database concurrent reads or not
    case concurrentDatabaseReads

    /// Limit playback position changes when switching episodes
    case limitPlaybackPositionChanges

    /// Use the new upgrade screens for account creation
    case newOnboardingAccountCreation

    /// Adds a sharing button to the transcript view
    case shareTranscripts

    /// Skips switching player to downloaded file if already playing from the same cached streamed file
    case doNotSwitchToDownloadedFile

    /// Do not show the free trial timeline on the upgrade screens on all variants
    case newOnboardingUpgradeTrialTimeline

    /// Use the new interests and recommendations flow
    case newOnboardingRecommendationChanges

    /// Use the new search endpoint and new UI
    case searchImprovements

    /// Use the new predictive endpoint and show predictions
    case searchPredictive

    /// Render Bookmarks inline in PodcastViewController using SwiftUI BookmarksListView
    case podcastBookmarksInline

    /// Enable reloading the subscription status in App Delegate
    case earlyReloadSubscriptionStatus

    /// Enable localization headers
    case enableLocalizationHeaders

    /// Enable the End of Year 2025 recap
    case endOfYear2025

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
        case .appThemePropertiesLogging:
            if BuildEnvironment.current == .debug {
                false
            } else {
                true
            }
        case .firebaseLogging:
            false
        case .endOfYear:
            false
        case .errorLogoutHandling:
            false
        case .newSettingsStorage:
            shouldEnableSyncedSettings
        case .settingsSync:
            shouldEnableSyncedSettings
        case .slumber:
            false
        case .newAccountUpgradePromptFlow:
            false
        case .streamAndCachePlayingEpisode:
            true
        case .defaultPlayerFilterCallbackFix:
            true
        case .downloadFixes:
            true
        case .onlyMarkPodcastsUnsyncedForNewUsers:
            true
        case .whenPlayingOnlyUpdateEpisodeIfPlaybackFails:
            true
        case .accelerateEffects:
            true
        case .kidsProfile:
            false
        case .upgradeExperiment:
            false
        case .ignoreRouteDisconnectedInterruption:
            true
        case .referrals:
            true
        case .referralsClaim:
            true
        case .referralsSend:
            true
        case .syncStats:
            true
        case .playerIsReadyToPlay:
            true
        case .listeningHistorySearch:
            true
        case .useMimetypePackage:
            true
        case .customPlaybackSettings:
            true
        case .runVacuumOnVersionUpdate:
            true
        case .endOfYear2024:
            false
        case .upNextShuffle:
            true
        case .autoDownloadOnSubscribe:
            true
        case .useFollowNaming:
            true
        case .useDefaultPlayerTapCookie:
            true
        case .markAllSyncedInSingleStatement:
            true
        case .winback:
            true
        case .manageDownloadedEpisodes:
			true
        case .useSyncResponseEpisodeIDs:
            true
        case .avoidLogoutInBackground:
            true
        case .disablePrivateFeedSharing:
            true
        case .podcastFeedUpdate:
            true
        case .downloadsThreadSafeCache:
            true
        case .suggestedFolders:
            true
        case .generatedTranscripts:
            true
        case .libroFm:
            false
        case .encourageAccountCreation:
            true
        case .refreshAndSaveWatchLogsOnSend:
            true
        case .avoidReplaceOnEpisodeSwap:
            true
        case .podcastsSortChanges:
            true
        case .recommendations:
            true
        case .cancelSubscriptionSurvey:
            true
        case .newOfferEligibilityCheck:
            true
        case .replaceSpecificEpisode:
            true
        case .episodeDetailTranscript:
            true
        case .bannerAdPodcasts:
            false
        case .bannerAdPlayer:
            false
        case .streamingCustomSessionConfiguration:
            true
        case .guestListsNetworkHighlightsRedesign:
            true
        case .smartCategories:
            true
        case .useDescriptiveActionAttributedTextView:
            true
        case .newOnboardingUpgrade:
            true
        case .newOnboardingVariant:
            true
        case .playlistsRebranding:
            false
        case .retryWithoutUserAgent:
            true
        case .userSatisfactionSurvey:
            true
        case .concurrentDatabaseReads:
            true
        case .limitPlaybackPositionChanges:
            true
        case .newOnboardingAccountCreation:
            true
        case .shareTranscripts:
            true
        case .doNotSwitchToDownloadedFile:
            true
        case .newOnboardingUpgradeTrialTimeline:
            false
        case .newOnboardingRecommendationChanges:
            true
        case .searchImprovements:
            false
        case .searchPredictive:
            true
        case .podcastBookmarksInline:
            true
        case .earlyReloadSubscriptionStatus:
            true
        case .enableLocalizationHeaders:
            true
        case .endOfYear2025:
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
        case .newAccountUpgradePromptFlow:
            "new_account_upgrade_prompt_flow"
        case .newSettingsStorage:
            shouldEnableSyncedSettings ? "new_settings_storage" : nil
        case .settingsSync:
            shouldEnableSyncedSettings ? "settings_sync" : nil
        case .defaultPlayerFilterCallbackFix:
            "default_player_filter_callback_fix"
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
