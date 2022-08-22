import Foundation
import PocketCastsDataModel

public extension UploadedSort {
    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.Localizable.podcastsEpisodeSortNewestToOldest
        case .oldestToNewest:
            return L10n.Localizable.podcastsEpisodeSortOldestToNewest
        case .titleAtoZ:
            return L10n.Localizable.uploadSortAlpha
        }
    }
}

public extension PodcastGrouping {
    var description: String {
        switch self {
        case .none:
            return L10n.Localizable.none
        case .downloaded:
            return L10n.Localizable.statusDownloaded
        case .unplayed:
            return L10n.Localizable.statusUnplayed
        case .season:
            return L10n.Localizable.season
        case .starred:
            return L10n.Localizable.statusStarred
        }
    }
}

public extension PlaylistSort {
    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.Localizable.podcastsEpisodeSortNewestToOldest
        case .oldestToNewest:
            return L10n.Localizable.podcastsEpisodeSortOldestToNewest
        case .shortestToLongest:
            return L10n.Localizable.podcastsEpisodeSortShortestToLongest
        case .longestToShortest:
            return L10n.Localizable.podcastsEpisodeSortLongestToShortest
        }
    }
}

public extension AutoAddToUpNextSetting {
    var description: String {
        switch self {
        case .off:
            return L10n.Localizable.off
        case .addLast:
            return L10n.Localizable.autoAddToBottom
        case .addFirst:
            return L10n.Localizable.autoAddToTop
        }
    }
}
