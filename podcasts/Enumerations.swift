import Foundation
import PocketCastsDataModel
enum LibraryType: Int {
    case fourByFour = 1, threeByThree = 2, list = 3
}

enum BadgeType: Int {
    case off = 0, latestEpisode, allUnplayed

    var description: String {
        switch self {
        case .off:
            return L10n.Localizable.off
        case .latestEpisode:
            return L10n.Localizable.podcastsBadgeLatestEpisode
        case .allUnplayed:
            return L10n.Localizable.podcastsBadgeAllUnplayed
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

enum PodcastEpisodeSortOrder: Int32, CaseIterable {
    case newestToOldest = 1, oldestToNewest, shortestToLongest, longestToShortest

    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.Localizable.podcastsEpisodeSortNewestToOldest.localizedCapitalized
        case .oldestToNewest:
            return L10n.Localizable.podcastsEpisodeSortOldestToNewest.localizedCapitalized
        case .shortestToLongest:
            return L10n.Localizable.podcastsEpisodeSortShortestToLongest
        case .longestToShortest:
            return L10n.Localizable.podcastsEpisodeSortLongestToShortest
        }
    }
}

enum LibrarySort: Int, CaseIterable {
    case dateAddedNewestToOldest = 1, titleAtoZ = 2, episodeDateNewestToOldest = 5, custom = 6

    var description: String {
        switch self {
        case .dateAddedNewestToOldest:
            return L10n.Localizable.podcastsLibrarySortDateAdded
        case .titleAtoZ:
            return L10n.Localizable.podcastsLibrarySortTitle
        case .episodeDateNewestToOldest:
            return L10n.Localizable.podcastsLibrarySortEpisodeReleaseDate
        case .custom:
            return L10n.Localizable.podcastsLibrarySortCustom
        }
    }
}

enum AppBadge: Int {
    case off = 0, totalUnplayed = 1, newSinceLastOpened = 2, filterCount = 10
}

enum PrimaryRowAction: Int32 {
    case stream = 0, download = 1
}

enum PrimaryUpNextSwipeAction: Int32 {
    case playNext = 0, playLast = 1
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

enum PlayerAction: Int, CaseIterable {
    case effects = 1, sleepTimer, routePicker, starEpisode, shareEpisode, goToPodcast, chromecast, markPlayed, archive
    
    func title(episode: BaseEpisode? = nil) -> String {
        switch self {
        case .effects:
            return L10n.Localizable.playerActionTitleEffects
        case .sleepTimer:
            return L10n.Localizable.playerActionTitleSleepTimer
        case .routePicker:
            return L10n.Localizable.playerActionTitleOutputOptions
        case .starEpisode:
            if episode?.keepEpisode ?? false {
                return L10n.Localizable.playerActionTitleUnstarEpisode
            }
            else {
                return L10n.Localizable.starEpisode
            }
        case .shareEpisode:
            return L10n.Localizable.share
        case .goToPodcast:
            if episode is UserEpisode {
                return L10n.Localizable.playerActionTitleGoToFile
            }
            else {
                return L10n.Localizable.goToPodcast
            }
        case .chromecast:
            // Note: Chromecast is a Propernoun and thus should not be translated.
            return "Chromecast"
        case .markPlayed:
            return L10n.Localizable.markPlayed
        case .archive:
            if episode is UserEpisode {
                return L10n.Localizable.delete
            }
            else {
                return L10n.Localizable.archive
            }
        }
    }
    
    func subtitle() -> String? {
        switch self {
        case .starEpisode, .shareEpisode:
            return L10n.Localizable.playerActionSubtitleHidden
        case .archive:
            return L10n.Localizable.playerActionSubtitleDelete
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
        }
    }
    
    func canBePerformedOn(episode: BaseEpisode) -> Bool {
        switch self {
        case .starEpisode, .shareEpisode:
            return episode is Episode
        default:
            return true
        }
    }
}

enum MultiSelectAction: Int32, CaseIterable {
    case playLast = 1, playNext, download, archive, markAsPlayed, star, moveToTop, moveToBottom, removeFromUpNext, unstar, unarchive, removeDownload, markAsUnplayed, delete
    
    func title() -> String {
        switch self {
        case .playLast:
            return L10n.Localizable.playLast
        case .playNext:
            return L10n.Localizable.playNext
        case .download:
            return L10n.Localizable.download
        case .archive:
            return L10n.Localizable.archive
        case .markAsPlayed:
            return L10n.Localizable.markPlayed
        case .star:
            return L10n.Localizable.multiSelectStar
        case .moveToTop:
            return L10n.Localizable.moveToTop
        case .moveToBottom:
            return L10n.Localizable.moveToBottom
        case .removeFromUpNext:
            return L10n.Localizable.remove
        case .unstar:
            return L10n.Localizable.multiSelectUnstar
        case .unarchive:
            return L10n.Localizable.unarchive
        case .removeDownload:
            return L10n.Localizable.removeDownload
        case .markAsUnplayed:
            return L10n.Localizable.multiSelectRemoveMarkUnplayed
        case .delete:
            return L10n.Localizable.delete
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
        }
    }
}
