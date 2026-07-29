import Foundation

// MARK: - Source

enum BookmarkAnalyticsSource: String, AnalyticsDescribable {
    case profile = "profile_screen"
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

// MARK: - Smart Bookmarks

/// Which of the two paths generated a bookmark's title and passage.
///
/// Bookmarks made with a headphone button, in CarPlay, or with the app backgrounded never
/// open the edit sheet, so the two paths have to be measurable apart.
enum BookmarkEnrichmentTrigger: String, AnalyticsDescribable {
    case editSheet = "edit_sheet"
    case background

    var analyticsDescription: String { rawValue }
}

/// Which model wrote a bookmark's title.
enum BookmarkTitleGenerator: String, AnalyticsDescribable {
    case onDevice = "on_device"
    case server

    var analyticsDescription: String { rawValue }
}

/// Why a title couldn't be generated from a passage.
enum BookmarkTitleFailureReason: String, AnalyticsDescribable {
    /// Device ineligible, Apple Intelligence off, or the model isn't downloaded
    case modelUnavailable = "model_unavailable"
    /// The on-device model refused the transcript as unsafe
    case guardrailViolation = "guardrail_violation"
    /// The on-device model failed for any other reason
    case onDeviceError = "on_device_error"
    /// The response was too long or otherwise not a title
    case unexpectedResponse = "unexpected_response"
    case serverError = "server_error"
    /// The server responded without a title
    case serverEmptyTitle = "server_empty_title"
    /// A title came back but was empty once trimmed
    case emptyTitle = "empty_title"
    /// The sheet was dismissed, or saved, before the title arrived
    case cancelled
    case unknown

    var analyticsDescription: String { rawValue }
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
        case .podcastAndEpisode:
            return "podcastAndEpisode"
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
