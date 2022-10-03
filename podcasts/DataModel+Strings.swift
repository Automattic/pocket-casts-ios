import Foundation
import PocketCastsDataModel

extension UploadedSort: AnalyticsDescribable {
    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.podcastsEpisodeSortNewestToOldest
        case .oldestToNewest:
            return L10n.podcastsEpisodeSortOldestToNewest
        case .titleAtoZ:
            return L10n.uploadSortAlpha
        }
    }

    var analyticsDescription: String {
        switch self {
        case .newestToOldest:
            return "newest_to_oldest"
        case .oldestToNewest:
            return "oldest_to_newest"
        case .titleAtoZ:
            return "title_a_to_z"
        }
    }
}

public extension PodcastGrouping {
    var description: String {
        switch self {
        case .none:
            return L10n.none
        case .downloaded:
            return L10n.statusDownloaded
        case .unplayed:
            return L10n.statusUnplayed
        case .season:
            return L10n.season
        case .starred:
            return L10n.statusStarred
        }
    }
}

public extension PlaylistSort {
    var description: String {
        switch self {
        case .newestToOldest:
            return L10n.podcastsEpisodeSortNewestToOldest
        case .oldestToNewest:
            return L10n.podcastsEpisodeSortOldestToNewest
        case .shortestToLongest:
            return L10n.podcastsEpisodeSortShortestToLongest
        case .longestToShortest:
            return L10n.podcastsEpisodeSortLongestToShortest
        }
    }
}

public extension AutoAddToUpNextSetting {
    var description: String {
        switch self {
        case .off:
            return L10n.off
        case .addLast:
            return L10n.autoAddToBottom
        case .addFirst:
            return L10n.autoAddToTop
        }
    }
}
