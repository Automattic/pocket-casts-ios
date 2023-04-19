import Foundation
import PocketCastsUtils
import UIKit

struct Constants {
    enum Notifications {
        static let upNextEpisodeAdded = NSNotification.Name(rawValue: "SJUpNextEpisodeAdded")
        static let upNextEpisodeRemoved = NSNotification.Name(rawValue: "SJUpNextEpisodeRemoved")
        static let upNextQueueChanged = NSNotification.Name(rawValue: "SJUpNextChanged")
        static let playbackStarted = NSNotification.Name(rawValue: "SJPlaybackStart")
        static let playbackStarting = NSNotification.Name(rawValue: "SJPlaybackStarting")
        static let playbackPaused = NSNotification.Name(rawValue: "SJPlaybackPaused")
        static let playbackProgress = NSNotification.Name(rawValue: "SJPlaybackProg")
        static let playbackTrackChanged = NSNotification.Name(rawValue: "SJTrackChanged")
        static let podcastChaptersDidUpdate = NSNotification.Name(rawValue: "SJChaptersChanged")
        static let podcastChapterChanged = NSNotification.Name(rawValue: "SJChapterChanged")
        static let podcastColorsDownloaded = NSNotification.Name(rawValue: "SJPodcastColorsReady")
        static let playbackEnded = NSNotification.Name(rawValue: "SJPlaybackEnd")
        static let playbackFailed = NSNotification.Name(rawValue: "playbackFailed")
        static let playbackPositionSaved = NSNotification.Name(rawValue: "SJPlayPosSaved")
        static let viewWillTransitionToSize = NSNotification.Name(rawValue: "SJViewSizeChange")
        static let googleCastStatusChanged = NSNotification.Name(rawValue: "SJGCStatusChanged")
        static let googleCastMultiZoneStatusChanged = NSNotification.Name(rawValue: "SJGCMultiStatusChanged")
        static let dimmingViewTapped = NSNotification.Name(rawValue: "SJDimViewTapped")
        static let downloadProgress = NSNotification.Name(rawValue: "SJDwnProg")
        static let podcastImageReCacheRequired = NSNotification.Name(rawValue: "PCPodcastImageReCacheRequired")
        static let episodeEmbeddedArtworkLoaded = NSNotification.Name(rawValue: "PCEpisodeEmbeddedArtworkLoaded")

        static let skipTimesChanged = NSNotification.Name(rawValue: "SJSkipTimesChanged")
        static let subscribeRequestedFromCell = NSNotification.Name(rawValue: "SJSubscribeRequestFromCell")
        static let chartRegionChanged = NSNotification.Name(rawValue: "SJChartRegionChanged")
        static let episodeDownloaded = NSNotification.Name(rawValue: "SJEpisodeDownloaded")
        static let miniPlayerDidDisappear = NSNotification.Name(rawValue: "SJMiniPlayerDisappeared")
        static let miniPlayerDidAppear = NSNotification.Name(rawValue: "SJMiniPlayerAppeared")
        static let filterChanged = NSNotification.Name(rawValue: "FilterChanged")
        static let playlistTempChange = NSNotification.Name(rawValue: "playlistTempChange")
        static let statusBarHeightChanged = NSNotification.Name(rawValue: "SJBarHeightChanged")
        static let podcastSearchRequest = NSNotification.Name(rawValue: "PodcastSearchRequest")
        static let podcastSearchCancelled = NSNotification.Name(rawValue: "PodcastSearchCancelled")
        static let removeUpcomingFromCell = NSNotification.Name(rawValue: "RemoveUpcomingFromCell")
        static let sideConstraintUpdated = NSNotification.Name(rawValue: "SJSideConstraintUpdated")
        static let themeChanged = NSNotification.Name(rawValue: "ThemeChanged")
        static let systemThemeMayHaveChanged = NSNotification.Name(rawValue: "SystemThemeChanged")
        static let followSystemThemeTurnedOn = NSNotification.Name(rawValue: "FollowSystemThemeTurnedOn")
        static let playbackEffectsChanged = NSNotification.Name(rawValue: "SJEffectsChanged")
        static let extraMediaSessionActionsChanged = NSNotification.Name(rawValue: "SJMediaSessionActionsChanged")
        static let currentlyPlayingEpisodeUpdated = NSNotification.Name(rawValue: "SJCurrentlyPlayingEpisodeUpdated")
        static let sleepTimerChanged = NSNotification.Name(rawValue: "SJSleepTimerChanged")
        static let unhideNavBarRequested = NSNotification.Name(rawValue: "SJUnhideNavBar")
        static let videoPlaybackEngineSwitched = NSNotification.Name(rawValue: "SJVideoPlaybackEngineSwitched")

        // episode notifications
        static let episodePlayStatusChanged = NSNotification.Name(rawValue: "SJEpPlayStatusChanged")
        static let episodeArchiveStatusChanged = NSNotification.Name(rawValue: "SJEpArchiveStatusChanged")
        static let episodeDurationChanged = NSNotification.Name(rawValue: "SJEpDurationChanged")
        static let episodeStarredChanged = NSNotification.Name(rawValue: "SJEpisodeStarredChanged")
        static let episodeDownloadStatusChanged = NSNotification.Name(rawValue: "SJEpisodeDownloadChanged")
        static let manyEpisodesChanged = NSNotification.Name(rawValue: "SJManyEpisodesChanged")

        // podcast notifications
        static let podcastUpdated = NSNotification.Name(rawValue: "SJPodcastUpdated")
        static let podcastAdded = NSNotification.Name(rawValue: "SJPodcastAdded")
        static let podcastDeleted = NSNotification.Name(rawValue: "SJPodDeleted")

        // user episode notifications
        static let userEpisodeDeleted = NSNotification.Name(rawValue: "SJUserEpisodeDeleted")
        static let userEpisodeUpdated = NSNotification.Name(rawValue: "SJUserEpisodeUpdated")

        // text editing
        static let textEditingDidStart = NSNotification.Name(rawValue: "SJTextEditingStarted")
        static let textEditingDidEnd = NSNotification.Name(rawValue: "SJTextEditingEnded")

        // shelf icons
        static let playerActionsUpdated = NSNotification.Name(rawValue: "SJPlayerActionsUpdated")

        // tabs
        static let tappedOnSelectedTab = NSNotification.Name(rawValue: "SJTappedOnSelectedTab")
        static let searchRequested = NSNotification.Name(rawValue: "SJTriggerSearch")

        // modal popups
        static let openingNonOverlayableWindow = NSNotification.Name(rawValue: "SJPresentingNonOverlayableWindow")
        static let closedNonOverlayableWindow = NSNotification.Name(rawValue: "SJClosedNonOverlayableWindow")

        static let opmlImportCompleted = NSNotification.Name(rawValue: "SJOpmlImportCompleted")
        static let opmlImportFailed = NSNotification.Name(rawValue: "SJOpmlImportFailed")

        // watch
        static let watchAutoDownloadSettingsChanged = NSNotification.Name(rawValue: "SJWatchAutoDownloadSettingsChanged")

        // folders
        /// This is triggered many times whenever a folder is changed
        static let folderChanged = NSNotification.Name(rawValue: "SJFolderChanged")
        static let folderDeleted = NSNotification.Name(rawValue: "SJFolderDeleted")
        /// This is triggered just once after a folder finishes editing
        static let folderEdited = NSNotification.Name(rawValue: "SJFolderEdited")

        // End of Year
        static let profileSeen = NSNotification.Name(rawValue: "profileSeen")
    }

    enum UserDefaults {
        static let globalRemoveSilence = "GlobalRemSilenceSetting"
        static let globalVolumeBoost = "GlobalVolBoostSetting"
        static let globalPlaybackSpeed = "SJGlobalSpeedSetting"
        static let episodeFinishedAction = "SJPodcastFinishedAction"
        static let appId = "SJUniqueAppId"

        static let keepScreenOnWhilePlaying = "SJKeepScreenOnWhenPlaying"
        static let openPlayerAutomatically = "SJOpenPlayerAutomatically"
        static let intelligentPlaybackResumption = "SJIntelligentPlaybackResumption"
        static let hideImagesInShowNotes = "HideImagesInShowNotes"
        static let loadEmbeddedImages = "SJLoadEmbeddedArt"
        static let appBadge = "SJEppBadgeShows"
        static let pushEnabled = "PushEnabled"
        static let globalEpisodesToKeep = "SJPodcastsToKeep"
        static let openLinksInExternalBrowser = "SJOpenLinksInExternalBrowser"

        static let appBadgeFilterUuid = "SJEppBadgeFilterId"
        static let lastAppCloseDate = "SJLastAppCloseDate"
        static let lastPlayEvent = "SJLastPlayEvent"
        static let cleanupUnplayed = "CleanupUnplayed"
        static let cleanupInProgress = "CleanupInProgress"
        static let cleanupPlayed = "CleanupPlayed"

        static let upNextLastModified = "SJUpNextLastModified"
        static let cleanupStarred = "CleanupStarred"
        static let lastFilterShown = "SJLastFilter"
        static let lastTabOpened = "SJLastTabOpened"
        static let lastImageRefreshTime = "SJLastImageRefreshDate"
        static let promotionFinishedAcknowledged = "SJPromotionFinishedAcknowledged"

        static let loginDetailsUpdated = "SJLoginDetailsUpdated"
        static let watchAutoDownloadUpNextEnabled = "SJWatchAutoDownloadUpNextEnabled"
        static let watchAutoDownloadUpNextCount = "SJWatchAutoDownloadCountUpNext"
        static let watchAutoDeleteUpNext = "SJWatchAutoDeleteUpNext"

        static let analyticsOptOut = "SJAnalyticsOptOut"

        static let supportName = "PCSupportRequestName"
        static let supportEmail = "PCSupportRequestEmail"
        static let supportRemoveDebugInfo = "PCSupportRemoveDebugInfo"

        static let lastPickerSort = "PCLastPickerSort"

        static let shouldFollowSystemThemeKey = "FollowSystemTheme"
        static let themeKey = "theme"

        static let lastRunVersion = "lastRunVersion"

        static let reviewRequestDates = "reviewRequestDates"

        static let showBadgeFor2022EndOfYear = "showBadgeFor2022EndOfYear"
        static let modal2022HasBeenShown = "modal2022HasBeenShown"
        static let hasSyncedAll2022Episodes = "hasSyncedAll2022Episodes"
        static let top5PodcastsListLink = "top5PodcastsListLink"
        static let shouldShowInitialOnboardingFlow = "shouldShowInitialOnboardingFlow"

        static let searchHistoryEntries = "SearchHistoryEntries"
    }

    enum Values {
        static let maxWidthForCompactView = 1000 as CGFloat
        static let sideBarWidthCompact = 88 as CGFloat
        static let sideBarWidthExpanded = 320 as CGFloat

        static let miniPlayerOffset = 72 as CGFloat
        static let extraShowNotesVerticalSpacing: CGFloat = 60
        static let defaultFilterDownloadLimit = 10 as Int32
        static let siriArtworkSize = 680

        static let minTimeBetweenPodcastImageUpdates = 4.weeks

        static let maxWidthForPopups: CGFloat = 500
        static let tableSectionHeaderHeight: CGFloat = 38

        static let refreshTaskId = "au.com.shiftyjelly.podcasts.Refresh"

        /// We show the free trial by default since if the app was just downloaded
        /// there is a chance it doesn't have a receipt and we won't be able to do a server check
        /// However Apple considers this user to be eligible
        public static let freeTrialDefaultValue = true
    }

    enum Limits {
        static let minTimeBetweenRemoteSkips: TimeInterval = 0.2
        static let maxDownloadConnectionsPerHost = 2
        static let upNextClearWithoutWarning = 2

        static let minSleepTime = 5.minutes
        static let maxSleepTime = 5.hours

        #if os(watchOS)
            static let watchListItems = 50
        #else
            static let maxListItemsToSendToWatch = 50
            static let maxFilterItems = 500
            static let maxCarplayItems = 100
            static let maxBulkDownloads = 100
            static let maxSubscriptionExpirySeconds: TimeInterval = 30.days
            static let maxShelfActions = 4
        #endif
    }

    enum Animation {
        static let defaultAnimationTime = 0.3 as TimeInterval
        static let bottomCardAnimationTime = 0.2 as TimeInterval
        static let playerDragLineFadeTime = 0.6 as TimeInterval
        static let multiSelectStatusDelayTime = 0.8 as TimeInterval
    }

    #if !os(watchOS)
        enum SiriActions {
            static let resumeId = "Resume ID"
            static let playPodcastId = "Play podcast ID"
            static let playSuggestedId = "Play suggested ID"
            static let playUpNextId = "play up next ID"
            static let playFilterId = "Play filter ID"
            static let playAllFilterId = "Play all filter ID"
            static let pauseId = "Pause ID"
            static let nextChapterId = "Next Chapter ID"
            static let previousChapterId = "Previous Chapter ID"
        }
    #endif

    enum Audio {
        static let defaultFrameSize = 1152
    }

    #if !os(watchOS)
        enum IapProducts: String {
            case yearly = "com.pocketcasts.plus.yearly"
            case monthly = "com.pocketcasts.plus.monthly"
            case patronYearly = "com.pocketcasts.patron.yearly"
            case patronMonthly = "com.pocketcasts.patron.monthly"

            var renewalPrompt: String {
                switch self {
                case .yearly, .patronYearly:
                    return L10n.accountPaymentRenewsYearly
                case .monthly, .patronMonthly:
                    return L10n.accountPaymentRenewsMonthly
                }
            }
        }

        enum Plan {
            case plus, patron

            var products: [Constants.IapProducts] {
                return [yearly, monthly]
            }

            var yearly: Constants.IapProducts {
                switch self {
                case .plus:
                    return .yearly
                case .patron:
                    return .patronYearly
                }
            }

            var monthly: Constants.IapProducts {
                switch self {
                case .plus:
                    return .monthly
                case .patron:
                    return .patronMonthly
                }
            }
        }
    #endif

    enum RemoteParams {
        static let periodicSaveTimeMs = "periodic_playback_save_ms"
        static let periodicSaveTimeMsDefault: Double = 60000

        static let podcastSearchDebounceMs = "podcast_search_debounce_ms"
        static let podcastSearchDebounceMsDefault: Double = 800

        static let episodeSearchDebounceMs = "episode_search_debounce_ms"
        static let episodeSearchDebounceMsDefault: Double = 800

        static let customStorageLimitGB = "custom_storage_limit_gb"
        static let customStorageLimitGBDefault: Int = 10

        static let endOfYearRequireAccount = "end_of_year_require_account"
        static let endOfYearRequireAccountDefault: Bool = true
    }

    static let defaultDebounceTime: TimeInterval = 0.5
}

enum PlusUpgradeViewSource: String {
    case profile
    case appearance
    case files
    case folders
    case themes
    case icons
    case watch
    case unknown

    /// Converts the enum into a Firebase promotionId, this matches the values set on Android
    func promotionId() -> String {
        return rawValue.uppercased()
    }

    /// Converts the enum into a Firebase promotion name, this matches the values set on Android
    func promotionName() -> String {
        switch self {
        case .profile, .appearance:
            return "Upgrade to Plus from \(rawValue)"

        case .unknown:
            return "Unknown"

        default:
            return "Upgrade to Plus for \(rawValue)"
        }
    }
}
