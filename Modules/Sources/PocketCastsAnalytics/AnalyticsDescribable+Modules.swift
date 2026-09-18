import Foundation
import PocketCastsDataModel
import PocketCastsServer

extension SubscriptionPlatform: AnalyticsDescribable {
    public var analyticsDescription: String {
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
    public var analyticsDescription: String {
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
    public var analyticsDescription: String {
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

extension SubscriptionTier: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .none:
            return "none"
        case .plus:
            return "plus"
        case .patron:
            return "patron"
        }
    }
}

extension AudioVideoFilter: AnalyticsDescribable {
    public var analyticsDescription: String {
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
    public var analyticsDescription: String {
        switch self {
        case .newestToOldest:
            return "newest_to_oldest"
        case .oldestToNewest:
            return "oldest_to_newest"
        case .shortestToLongest:
            return "shortest_to_longest"
        case .longestToShortest:
            return "longest_to_shortest"
        case .dragAndDrop:
            return "drag_and_drop"
        }
    }
}

extension AutoAddToUpNextSetting: AnalyticsDescribable {
    public var analyticsDescription: String {
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

extension AutoArchiveAfterTime: AnalyticsDescribable {
    public var analyticsDescription: String {
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
    public var analyticsDescription: String {
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
    public var analyticsDescription: String {
        switch self {
        case .stopAdding:
            return "stop_adding"
        case .addToTopOnly:
            return "only_add_top"
        }
    }
}

extension PodcastInfo: AnalyticsDescribable {
    public var analyticsDescription: String {
        if let uuid {
            return uuid
        }

        if let iTunesId {
            return String(iTunesId)
        }

        return "unknown"
    }
}

extension SocialAuthProvider: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .apple:
            return "apple"
        case .google:
            return "google"
        }
    }
}

extension LibraryType: AnalyticsDescribable {
    public var analyticsDescription: String {
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

extension BadgeType: AnalyticsDescribable {
    public var analyticsDescription: String {
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

extension PodcastEpisodeSortOrder: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .titleAtoZ:
            return "title_a_to_z"
        case .titleZtoA:
            return "title_z_to_a"
        case .newestToOldest:
            return "newest_to_oldest"
        case .oldestToNewest:
            return "oldest_to_newest"
        case .shortestToLongest:
            return "shortest_to_longest"
        case .longestToShortest:
            return "longest_to_shortest"
        case .serial:
            return "serial"
        }
    }
}

extension LibrarySort: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .dateAddedNewestToOldest:
            return "date_added"
        case .titleAtoZ:
            return "name"
        case .episodeDateNewestToOldest:
            return "episode_release_date"
        case .custom:
            return "drag_and_drop"
        case .recentlyPlayed:
            return "episode_recently_played"
        }
    }
}

extension AppBadge: AnalyticsDescribable {
    public var analyticsDescription: String {
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

extension PrimaryRowAction: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .stream:
            return "play"
        case .download:
            return "download"
        }
    }
}

extension PrimaryUpNextSwipeAction: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .playNext:
            return "play_next"
        case .playLast:
            return "play_last"
        }
    }
}

extension PlayerAction: AnalyticsDescribable {
    public var analyticsDescription: String {
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
        case .transcript:
            return "transcript"
        case .download:
            return "download"
        case .addToPlaylist:
            return "add_to_playlist"
        case .videoToggle:
            return "video_toggle"
        }
    }
}

extension ThemeType: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .light:
            return"default_light"
        case .dark:
            return "default_dark"
        case .extraDark:
            return "extra_dark"
        case .electric:
            return "electric"
        case .classic:
            return "classic"
        case .indigo:
            return "indigo"
        case .rosé:
            return "rose"
        case .contrastLight:
            return "light_contrast"
        case .contrastDark:
            return "dark_contrast"
        }
    }
}

extension TrimSilenceAmount: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .off:
            return "off"
        case .low:
            return "mild"
        case .medium:
            return "medium"
        case .high:
            return "mad_max"
        }
    }
}

extension UploadedSort: AnalyticsDescribable {
    public var analyticsDescription: String {
        switch self {
        case .newestToOldest:
            return "newest_to_oldest"
        case .oldestToNewest:
            return "oldest_to_newest"
        case .titleAtoZ:
            return "title_a_to_z"
        case .titleZtoA:
            return "title_z_to_a"
        case .shortestToLongest:
            return "shortest_to_longest"
        case .longestToShortest:
            return "longest_to_shortest"
        }
    }
}

extension EpisodeSearchResult: AnalyticsDescribable {
    public var analyticsDescription: String {
        "episode"
    }
}

extension PodcastFolderSearchResult: AnalyticsDescribable {
    public var analyticsDescription: String {
        if kind == .folder {
            return "folder"
        } else if isLocal == true {
            return "podcast_local_result"
        } else {
            return "podcast_remote_result"
        }
    }
}

extension NetworkSearchResult: AnalyticsDescribable {
    public var analyticsDescription: String {
        "network"
    }
}
