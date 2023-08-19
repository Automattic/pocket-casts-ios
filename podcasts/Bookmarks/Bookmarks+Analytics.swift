import Foundation

// MARK: - Source

enum BookmarkAnalyticsSource: String, AnalyticsDescribable {
    case podcasts = "podcast_screen"
    case episodes = "episode_details"
    case player
    case files
    case headphones

    case unknown

    var analyticsDescription: String {
        rawValue
    }
}

extension BookmarkSortOption: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .newestToOldest:
            return "date_added_newest_to_oldest"
        case .oldestToNewest:
            return "date_added_oldest_to_newest"
        case .timestamp:
            return "timestamp"
        }
    }
}
