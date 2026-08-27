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

    /// Show the modal about the partnership with Slumber Studios
    case slumber

    /// Enable the new flow for Account upgrade prompt where it start IAP flow directly from account cell
    case newAccountUpgradePromptFlow

    /// Enable the AVExportSession parallel download of any playing episode
    case streamAndCachePlayingEpisode

    /// Enables the Kids banner
    case kidsProfile

    /// Enable the new Upgrade Experiments
    case upgradeExperiment

    /// Enable the Referrals feature
    case referrals

    /// Enables the referrals Send Flow
    case referralsSend

    /// Enables the referrals Claim Flow
    case referralsClaim

    /// Run a vacuum process on the database in order to optimize data fetch
    case runVacuumOnVersionUpdate

    /// Enable the End of Year 2024 recap
    case endOfYear2024

    /// Push two auto downloads on subscribe of a podcast
    case autoDownloadOnSubscribe

    /// Enable the winback screen and flow
    case winback

    /// Enable/Disable the podcast feed reload feature
    case podcastFeedUpdate

    /// Enable/Disable the use of a thread safe ongoing downloads cache
    case downloadsThreadSafeCache

    /// Enable Disable the use of suggested folders
    case suggestedFolders

    /// Enable the generated transcript
    case generatedTranscripts

    /// Enable synced transcripts with playback timing
    case syncedTranscripts

    /// Encourage Account Creation
    case encourageAccountCreation

    /// Enable Libro.fm icons in Paywall
    case libroFm

    /// Any time watch data is sent, we refresh the watch logs and save them to a file for sending to Zendesk or exporting
    case refreshAndSaveWatchLogsOnSend

    /// Avoid replace actions for Up Next episode queue when swapping the currently playing episode
    case avoidReplaceOnEpisodeSwap

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

    /// Adds Discover category user recommendations
    case smartCategories

    /// Enabled the attributed text view in the Data Usage warning Sheet
    case useDescriptiveActionAttributedTextView

    /// Use the new upgrade screens with Variant B timeline before features
    case newOnboardingVariant

    /// Retry failed downloads and stream without the user agent
    case retryWithoutUserAgent

    /// Show a satisfaction survey before prompting to rate
    case userSatisfactionSurvey

    /// Whether to use database concurrent reads or not
    case concurrentDatabaseReads

    /// Limit playback position changes when switching episodes
    case limitPlaybackPositionChanges

    /// Adds a sharing button to the transcript view
    case shareTranscripts

    /// Skips switching player to downloaded file if already playing from the same cached streamed file
    case doNotSwitchToDownloadedFile

    /// Do not show the free trial timeline on the upgrade screens on all variants
    case newOnboardingUpgradeTrialTimeline

    /// Use the new predictive endpoint and show predictions
    case searchPredictive

    /// Enable reloading the subscription status in App Delegate
    case earlyReloadSubscriptionStatus

    /// Enable localization headers
    case enableLocalizationHeaders

    /// Enable the End of Year 2025 recap
    case endOfYear2025

    /// Enable the End of Year to use first story as loading screen
    case endOfYearLoadIsFirstStory

    /// Upgrades the Effects Player's AudioReadTask to a QOS level of "userInitiated" from "default"
    case effectsPlayerQOSUpgrade

    /// Uses the PlaylistMetadataLoader cache before running the query (the query will update when it's done)
    case playlistDataCacheBeforeQuery

    /// Ignores play remote commands when another app is playing non-mixable audio
    case ignorePlayWithOtherAudio

    /// Use cellular-specific network APIs instead of expensive network APIs
    case useCellularNetworkApis

    /// Optimizes manual playlist queries with improved deduplication
    case optimizeManualPlaylistQueries

    /// Use a background queue for streaming callbacks
    case useBackgroundQueueForStreamingCallback

    /// Moves the shouldKeepPlaying after we check that the episode is over
    case checkFinishedTimeBeforeShouldKeepPlaying

    /// Activate audio session to enable multi-speaker selection in route picker
    case activateAudioSessionForRoutePicker

    /// Don't autoplay when route changes
    case dontAutoplayOnRouteChange

    /// Allow the release of the Media Exporter when is no longer being used by the player
    case releaseMediaExporterWhenNoLongerActive

    /// Fix Watch app overwriting phone's Up Next queue by adding debouncing and fixing timestamp comparison logic
    case watchUpNextSyncFix

    /// Enable VoiceBoostN with updated description copy (TestFlight only)
    case voiceBoostN

    /// Use GRDB QueryInterface for database queries instead of raw SQL
    case grdbQueryInterface

    /// Adds invalidation to the playlist cache on appearance when its been > 30 seconds
    case playlistCacheInvalidation

    /// Use WCSessionFileTransfer to send logs from watchOS to iPhone instead of sendMessage reply
    case watchLogFileTransfer

    /// Skip Up Next sync when protected data is unavailable to prevent sync with incorrect UserDefaults values
    case skipSyncWhenProtectedDataUnavailable

    /// Check if protected data is available before running migrations that touch keychain
    case checkProtectedDataBeforeMigration

    /// Use transferUserInfo API for watch-to-phone actions and sendMessage for phone-to-watch state updates
    case watchTransferUserInfoApi

    /// Remove the 50-episode limit when syncing Up Next to Apple Watch
    case unlimitedWatchUpNextSync

    /// On pause, sync the playback position directly between the watch and phone over
    /// WatchConnectivity (both directions) so progress appears on the other device without a manual refresh
    case watchPlaybackProgressLocalSync

    /// Ensure that tmp files are removed when no longer needed
    case cleanUpTmpFiles

    /// Display playback errors on player
    case displayErrorsOnPlayer

    /// Detect truncated background sync downloads by comparing received bytes to Content-Length
    case detectTruncatedBackgroundSyncDownloads

    /// Track network data usage per episode/connection type in the NetworkDataUsage table
    case trackNetworkDataUsage

    /// Show the listening activity heatmap on the Stats screen
    case statsHeatmap

    /// Show explicit content badges on podcasts
    case showExplicitBadges

    /// Enable the Share Profile feature
    case shareProfile

    /// Enable the Up Next sort button
    case upNextSort

    /// Enable Generated Chapters
    case generatedChapters

    /// Enable HLS streaming playback
    case hls

    /// A new "Troubleshooting" screen for detecting orphaned episodes and more.
    case troubleshooting

    /// Enable Smart Bookmarks
    case smartBookmarks

    /// Use best frame when capturing a thumbnail for video cells
    case captureBestFrame

    /// Make the tab bar's minimize-on-scroll behavior opt-in: it's off unless the
    /// user turns it on in Appearance
    case minimizeTabsOptIn

    /// Introduce Smart Bookmarks with a tip in the player and a "New" badge on the Add Bookmark row.
    ///
    /// The promo runs for 8.19, 8.20 and 8.21 only. Remove this flag and `SmartBookmarksPromo` when 8.22 is cut.
    case smartBookmarksPromo

    /// Show a Live Activity on the Lock Screen and Dynamic Island while the sleep timer is running
    case sleepTimerLiveActivity

    /// Enable the network discovery Discover sections and podcast page entry points
    case networkDiscovery

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
        case .slumber:
            false
        case .newAccountUpgradePromptFlow:
            false
        case .streamAndCachePlayingEpisode:
            true
        case .kidsProfile:
            false
        case .upgradeExperiment:
            false
        case .referrals:
            true
        case .referralsClaim:
            true
        case .referralsSend:
            true
        case .runVacuumOnVersionUpdate:
            false
        case .endOfYear2024:
            false
        case .autoDownloadOnSubscribe:
            true
        case .winback:
            true
        case .podcastFeedUpdate:
            true
        case .downloadsThreadSafeCache:
            true
        case .suggestedFolders:
            true
        case .generatedTranscripts:
            true
        case .syncedTranscripts:
            true
        case .libroFm:
            false
        case .encourageAccountCreation:
            true
        case .refreshAndSaveWatchLogsOnSend:
            true
        case .avoidReplaceOnEpisodeSwap:
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
        case .smartCategories:
            true
        case .useDescriptiveActionAttributedTextView:
            true
        case .newOnboardingVariant:
            true
        case .retryWithoutUserAgent:
            true
        case .userSatisfactionSurvey:
            true
        case .concurrentDatabaseReads:
            true
        case .limitPlaybackPositionChanges:
            true
        case .shareTranscripts:
            true
        case .doNotSwitchToDownloadedFile:
            true
        case .newOnboardingUpgradeTrialTimeline:
            true
        case .searchPredictive:
            true
        case .earlyReloadSubscriptionStatus:
            true
        case .enableLocalizationHeaders:
            true
        case .endOfYear2025:
            false
        case .endOfYearLoadIsFirstStory:
			true
        case .effectsPlayerQOSUpgrade:
            true
        case .playlistDataCacheBeforeQuery:
            true
        case .ignorePlayWithOtherAudio:
            true
        case .useCellularNetworkApis:
            true
        case .optimizeManualPlaylistQueries:
            true
        case .useBackgroundQueueForStreamingCallback:
			true
        case .checkFinishedTimeBeforeShouldKeepPlaying:
            true
        case .activateAudioSessionForRoutePicker:
            true
        case .dontAutoplayOnRouteChange:
            true
        case .releaseMediaExporterWhenNoLongerActive:
            true
        case .watchUpNextSyncFix:
            true
        case .voiceBoostN:
            false
        case .grdbQueryInterface:
            true
        case .playlistCacheInvalidation:
            true
        case .watchLogFileTransfer:
            true
        case .skipSyncWhenProtectedDataUnavailable:
            true
        case .checkProtectedDataBeforeMigration:
			      true
        case .watchTransferUserInfoApi:
            true
        case .unlimitedWatchUpNextSync:
            true
        case .watchPlaybackProgressLocalSync:
            true
        case .cleanUpTmpFiles:
            true
        case .displayErrorsOnPlayer:
            true
        case .detectTruncatedBackgroundSyncDownloads:
            true
        case .trackNetworkDataUsage:
            true
        case .statsHeatmap:
            true
        case .showExplicitBadges:
            true
        case .shareProfile:
            BuildEnvironment.current == .debug
        case .upNextSort:
            true
        case .generatedChapters:
            BuildEnvironment.current == .debug
        case .hls:
            true
        case .troubleshooting:
            true
        case .smartBookmarks:
            true
        case .captureBestFrame:
            true
        case .minimizeTabsOptIn:
            true
        case .smartBookmarksPromo:
            true
        case .sleepTimerLiveActivity:
            true
        case .networkDiscovery:
            BuildEnvironment.current == .debug
        }
    }

    /// Remote Feature Flag
    /// This should match a Firebase Remote Config Parameter name (key)
    public var remoteKey: String? {
        switch self {
        case .newAccountUpgradePromptFlow:
            "new_account_upgrade_prompt_flow"
        case .endOfYear2025:
            "end_of_year_2025"
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
