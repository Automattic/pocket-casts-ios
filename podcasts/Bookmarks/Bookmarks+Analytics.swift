import Foundation

// MARK: - Source

enum BookmarkAnalyticsSource: String, AnalyticsDescribable {
    case podcasts = "podcast_screen"
    case episodes = "episode_details"
    case player
    case files
    case headphones
    case whatsNew = "whats_new"

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
        case .episode:
            return "episode"
        }
    }
}

extension HeadphoneControlAction: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .skipBack:
            return "skip_back"
        case .skipForward:
            return "skip_forward"
        case .previousChapter:
            return "previous_chapter"
        case .nextChapter:
            return "next_chapter"
        case .addBookmark:
            return "add_bookmark"
        }
    }
}
