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

extension AutoAddToUpNextSetting: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .off:
            return "off"
        case .addLast:
            return "add_last"
        case .addFirst:
            return "add_first"
        }
    }
}

enum AutoArchiveAfterTime: TimeInterval, AnalyticsDescribable {
    case never = -1
    case afterPlaying = 0
    case after1Day = 86400
    case after2Days = 172_800
    case after1Week = 604_800
    case after2Weeks = 1_209_600
    case after30Days = 2_592_000
    case after90Days = 7_776_000

    var analyticsDescription: String {
        switch self {
        case .never:
            return "never"
        case .afterPlaying:
            return "after_playing"
        case .after1Day:
            return "after_24_hours"
        case .after2Days:
            return "after_2_days"
        case .after1Week:
            return "after_1_week"
        case .after2Weeks:
            return "after_2_weeks"
        case .after30Days:
            return "after_30_days"
        case .after90Days:
            return "after_3_months"
        }
    }
}

extension PodcastGrouping: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .none:
            return "none"
        case .downloaded:
            return "downloaded"
        case .unplayed:
            return "unplayed"
        case .season:
            return "season"
        case .starred:
            return "starred"
        }
    }
}

extension AutoAddLimitReachedAction: AnalyticsDescribable {
    var analyticsDescription: String {
        switch self {
        case .stopAdding:
            return "stop_adding"
        case .addToTopOnly:
            return "only_add_top"
        }
    }
}

extension PodcastInfo: AnalyticsDescribable {
    var analyticsDescription: String {
        if let uuid {
            return uuid
        }

        if let iTunesId {
            return String(iTunesId)
        }

        return "unknown"
    }
}
