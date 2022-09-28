import Foundation
import PocketCastsDataModel
import PocketCastsServer

extension SubscriptionPlatform: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .none:
            return "none"
        case .iOS:
            return "ios"
        case .android:
            return "android"
        case .web:
            return "web"
        case .gift:
            return "gift"
        }
    }
}

extension SubscriptionFrequency: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .none:
            return "none"
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        }
    }
}

extension SubscriptionType: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .none:
            return "none"
        case .plus:
            return "plus"
        case .supporter:
            return "supporter"
        }
    }
}

extension AudioVideoFilter: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .all:
            return "all"
        case .audioOnly:
            return "audio"
        case .videoOnly:
            return "video"
        }
    }
}

extension PlaylistSort: AnalyticsDescribable {
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
