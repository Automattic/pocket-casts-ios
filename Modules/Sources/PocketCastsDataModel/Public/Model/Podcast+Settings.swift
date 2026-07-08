import PocketCastsUtils
import Foundation

extension Podcast {
    public var isEffectsOverridden: Bool {
        get {
            overrideGlobalEffects
        }
        set {
            overrideGlobalEffects = newValue
        }
    }

    public var autoStartFrom: Int32 {
        get {
            startFrom
        }
        set {
            startFrom = newValue
        }
    }

    public var autoSkipLast: Int32 {
        get {
            skipLast
        }
        set {
            skipLast = newValue
        }
    }

    public var podcastSortOrder: PodcastEpisodeSortOrder? {
        PodcastEpisodeSortOrder(old: PodcastEpisodeSortOrder.Old(rawValue: episodeSortOrder) ?? .newestToOldest)
    }

    public var autoArchivePlayedAfterTime: TimeInterval {
        get {
            autoArchivePlayedAfter
        }
        set {
            autoArchivePlayedAfter = newValue
        }
    }

    public var autoArchiveInactiveAfterTime: TimeInterval {
        get {
            autoArchiveInactiveAfter
        }
        set {
            autoArchiveInactiveAfter = newValue
        }
    }

    public var autoArchiveEpisodeLimitCount: Int32 {
        get {
            autoArchiveEpisodeLimit
        }
        set {
            autoArchiveEpisodeLimit = newValue
        }
    }

    public var isAutoArchiveOverridden: Bool {
        get {
            overrideGlobalArchive
        }
        set {
            overrideGlobalArchive = newValue
        }
    }

    public var shouldShowArchived: Bool {
        get {
            showArchived
        }
        set {
            showArchived = newValue
        }
    }

    public var isPushEnabled: Bool {
        get {
            pushEnabled
        }
        set {
            pushEnabled = newValue
        }
    }
}
