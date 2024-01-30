import Foundation
import PocketCastsDataModel
enum LibraryType: Int, AnalyticsDescribable {
    case fourByFour = 1, threeByThree = 2, list = 3

    var analyticsDescription: String {
        switch self {
        case .fourByFour:
            return "four_by_four"
        case .threeByThree:
            return "three_by_three"
        case .list:
            return "list"
        }
    }
}

enum BadgeType: Int, AnalyticsDescribable {
    case off = 0, latestEpisode, allUnplayed

    var description: String {
        switch self {
        case .off:
            return L10n.off
        case .latestEpisode:
            return L10n.podcastsBadgeLatestEpisode
        case .allUnplayed:
            return L10n.podcastsBadgeAllUnplayed
        }
    }

    var analyticsDescription: String {
        switch self {
        case .off:
            return "off"
        case .latestEpisode:
            return "only_latest_episode"
        case .allUnplayed:
            return "unfinished_episodes"
        }
    }
}

enum PodcastFinishedAction: Int {
    case doNothing = 0, delete
}

enum PodcastThumbnailSize {
    case list, grid, page
}

enum PodcastLicensing: Int32 {
    case keepEpisodesAfterExpiry = 0, deleteEpisodesAfterExpiry = 1
}

enum PodcastEpisodeSortOrder: Int32, CaseIterable, AnalyticsDescribable {
    case newestToOldest = 1, oldestToNewest, shortestToLongest, longestToShortest

    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.podcastsEpisodeSortNewestToOldest.localizedCapitalized
        case .oldestToNewest:
            return L10n.podcastsEpisodeSortOldestToNewest.localizedCapitalized
        case .shortestToLongest:
            return L10n.podcastsEpisodeSortShortestToLongest
        case .longestToShortest:
            return L10n.podcastsEpisodeSortLongestToShortest
        }
    }

    var analyticsDescription: String {
        switch self {

        case .newestToOldest:
            return "newest_to_oldest"
        case .oldestToNewest:
            return "oldest_to_newest"
        case .shortestToLongest:
            return "shortest_to_longest"
        case .longestToShortest:
            return "longest_to_shortest"
        }
    }
}

enum LibrarySort: Int, CaseIterable, AnalyticsDescribable {
    case dateAddedNewestToOldest = 1, titleAtoZ = 2, episodeDateNewestToOldest = 5, custom = 6

    var description: String {
        switch self {
        case .dateAddedNewestToOldest:
            return L10n.podcastsLibrarySortDateAdded
        case .titleAtoZ:
            return L10n.podcastsLibrarySortTitle
        case .episodeDateNewestToOldest:
            return L10n.podcastsLibrarySortEpisodeReleaseDate
        case .custom:
            return L10n.podcastsLibrarySortCustom
        }
    }

    var analyticsDescription: String {
        switch self {
        case .dateAddedNewestToOldest:
            return "date_added"
        case .titleAtoZ:
            return "name"
        case .episodeDateNewestToOldest:
            return "episode_release_date"
        case .custom:
            return "drag_and_drop"
        }
    }
}

enum AppBadge: Int, AnalyticsDescribable {
    case off = 0, totalUnplayed = 1, newSinceLastOpened = 2, filterCount = 10

    var analyticsDescription: String {
        switch self {
        case .off:
            return "off"
        case .totalUnplayed:
            return "total_unplayed"
        case .newSinceLastOpened:
            return "new_since_app_opened"
        case .filterCount:
            return "filter_count"
        }
    }
}

enum PrimaryRowAction: Int32, AnalyticsDescribable {
    case stream = 0, download = 1

    var analyticsDescription: String {
        switch self {
        case .stream:
            return "play"
        case .download:
            return "download"
        }
    }
}

enum PrimaryUpNextSwipeAction: Int32, AnalyticsDescribable {
    case playNext = 0, playLast = 1

    var analyticsDescription: String {
        switch self {
        case .playNext:
            return "play_next"
        case .playLast:
            return "play_last"
        }
    }
}

enum PlaylistIcon: Int32 {
    case redPlaylist = 0, bluePlaylist, greenPlaylist, purplePlaylist, yellowPlaylist,
         redmostPlayed, bluemostPlayed, greenmostPlayed, purplemostPlayed, yellowmostPlayed,
         redRecent, blueRecent, greenRecent, purpleRecent, yellowRecent,
         redDownloading, blueDownloading, greenDownloading, purpleDownloading, yellowDownloading,
         redUnplayed, blueUnplayed, greenUnplayed, purpleUnplayed, yellowUnplayed,
         redAudio, blueAudio, greenAudio, purpleAudio, yellowAudio,
         redVideo, blueVideo, greenVideo, purpleVideo, yellowVideo,
         redTop, blueTop, greenTop, purpleTop, yellowTop
}

enum PlayerAction: Int, AnalyticsDescribable {
    case effects = 1, sleepTimer, routePicker, starEpisode, shareEpisode, goToPodcast, chromecast, markPlayed, archive, addBookmark

    /// Specify default actions and their order
    static var defaultActions: [PlayerAction] {
        [
            .effects, .sleepTimer, .routePicker, .starEpisode,
            .shareEpisode, .goToPodcast, .chromecast, .markPlayed,
            .addBookmark, .archive
        ]
    }

    func title(episode: BaseEpisode? = nil) -> String {
        switch self {
        case .effects:
            return L10n.playerActionTitleEffects
        case .sleepTimer:
            return L10n.playerActionTitleSleepTimer
        case .routePicker:
            return L10n.playerActionTitleOutputOptions
        case .starEpisode:
            if episode?.keepEpisode ?? false {
                return L10n.playerActionTitleUnstarEpisode
            } else {
                return L10n.starEpisode
            }
        case .shareEpisode:
            return L10n.share
        case .goToPodcast:
            if episode is UserEpisode {
                return L10n.playerActionTitleGoToFile
            } else {
                return L10n.goToPodcast
            }
        case .chromecast:
            // Note: Chromecast is a Propernoun and thus should not be translated.
            return "Chromecast"
        case .markPlayed:
            return L10n.markPlayed
        case .archive:
            if episode is UserEpisode {
                return L10n.delete
            } else {
                return L10n.archive
            }

        case .addBookmark:
            return L10n.addBookmark
        }
    }

    func subtitle() -> String? {
        switch self {
        case .starEpisode, .shareEpisode:
            return L10n.playerActionSubtitleHidden
        case .archive:
            return L10n.playerActionSubtitleDelete
        default:
            return nil
        }
    }

    func iconName(episode: BaseEpisode?) -> String {
        switch self {
        case .effects:
            return "effects-off"
        case .sleepTimer:
            return "sleep-menu"
        case .routePicker:
            return "route_picker"
        case .starEpisode:
            return (episode?.keepEpisode ?? false) ? "player_star_filled" : "player_star_empty"
        case .shareEpisode:
            return "podcast-share"
        case .goToPodcast:
            return "gotoarrow"
        case .chromecast:
            return "nav_cast_off"
        case .markPlayed:
            return "episode-markasplayed"
        case .archive:
            return episode is UserEpisode ? "delete-red" : "episode-archive"
        case .addBookmark:
            return "bookmarks-shelf-overflow-icon"
        }
    }

    func largeIconName(episode: BaseEpisode?) -> String {
        switch self {
        case .effects:
            return "effects-off"
        case .sleepTimer:
            return "sleep-menu"
        case .routePicker:
            return ""
        case .starEpisode:
            return (episode?.keepEpisode ?? false) ? "player_star_filled" : "player_star_empty"
        case .shareEpisode:
            return "shelf_share"
        case .goToPodcast:
            return "shelf_gotoarrow"
        case .chromecast:
            return "shelf_nav_cast_off"
        case .markPlayed:
            return "shelf_played"
        case .archive:
            return episode is UserEpisode ? "shelf_delete" : "shelf_archive"
        case .addBookmark:
            return "bookmarks-shelf-icon"
        }
    }

    func canBePerformedOn(episode: BaseEpisode) -> Bool {
        switch self {
        case .starEpisode, .shareEpisode:
            return episode is Episode
        case .addBookmark:
            return isAvailable
        default:
            return true
        }
    }

    /// Determines whether the action should be available as an option
    /// If false, the action will be hidden from the player shelf and overflow menu
    var isAvailable: Bool {
        switch self {
        default:
            return true
        }
    }

    var analyticsDescription: String {
        switch self {
        case .effects:
            return "playback_effects"
        case .sleepTimer:
            return "sleep_timer"
        case .routePicker:
            return "route_picker"
        case .starEpisode:
            return "star_episode"
        case .shareEpisode:
            return "share_episode"
        case .goToPodcast:
            return "go_to_podcast"
        case .chromecast:
            return "chromecast"
        case .markPlayed:
            return "mark_as_played"
        case .archive:
            return "archive"
        case .addBookmark:
            return "bookmark"
        }
    }
}

enum MultiSelectAction: Int32, CaseIterable, AnalyticsDescribable {
    case playLast = 1, playNext, download, archive, markAsPlayed, star, moveToTop, moveToBottom, removeFromUpNext, unstar, unarchive, removeDownload, markAsUnplayed, delete, share

    func title() -> String {
        switch self {
        case .playLast:
            return L10n.playLast
        case .playNext:
            return L10n.playNext
        case .download:
            return L10n.download
        case .archive:
            return L10n.archive
        case .markAsPlayed:
            return L10n.markPlayed
        case .star:
            return L10n.multiSelectStar
        case .moveToTop:
            return L10n.moveToTop
        case .moveToBottom:
            return L10n.moveToBottom
        case .removeFromUpNext:
            return L10n.remove
        case .unstar:
            return L10n.multiSelectUnstar
        case .unarchive:
            return L10n.unarchive
        case .removeDownload:
            return L10n.removeDownload
        case .markAsUnplayed:
            return L10n.multiSelectRemoveMarkUnplayed
        case .delete:
            return L10n.delete
        case .share:
            return L10n.share
        }
    }

    func iconName() -> String {
        switch self {
        case .playLast:
            return "playlast"
        case .playNext:
            return "playnext"
        case .download:
            return "player-download"
        case .archive:
            return "episode-archive"
        case .markAsPlayed:
            return "episode-markasplayed"
        case .star:
            return "profile-star"
        case .moveToTop:
            return "upnext-movetotop"
        case .moveToBottom:
            return "upnext-movetobottom"
        case .removeFromUpNext:
            return "episode-removenext"
        case .unstar:
            return "episode-unstar"
        case .unarchive:
            return "episode-unarchive"
        case .markAsUnplayed:
            return "episode-markunplayed"
        case .removeDownload:
            return "episode-remove-download"
        case .delete:
            return "episode-delete"
        case .share:
            return "podcast-share"
        }
    }

    var analyticsDescription: String {
        switch self {
        case .playLast:
            return "play_last"
        case .playNext:
            return "play_next"
        case .download:
            return "download"
        case .archive:
            return "archive"
        case .markAsPlayed:
            return "mark_as_played"
        case .star:
            return "star"
        case .moveToTop:
            return "up_next_move_up"
        case .moveToBottom:
            return "up_next_move_bottom"
        case .removeFromUpNext:
            return "up_next_remove"
        case .unstar:
            return "unstar"
        case .unarchive:
            return "unarchive"
        case .markAsUnplayed:
            return "mark_unplayed"
        case .removeDownload:
            return "remove_download"
        case .delete:
            return "delete"
        case .share:
            return "share"
        }
    }

    func isVisible(with episodes: [BaseEpisode]) -> Bool {
        switch self {
        case .share:
            return episodes.count == 1 && episodes.allSatisfy({ $0 is Episode })

        default:
            return true
        }
    }
}
