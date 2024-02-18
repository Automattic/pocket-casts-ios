import PocketCastsUtils
import Foundation

extension Podcast {
    public var isEffectsOverridden: Bool {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.customEffects
            } else {
                return overrideGlobalEffects
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.customEffects = newValue
            } else {
                overrideGlobalEffects = newValue
            }
        }
    }

    public var autoStartFrom: Int32 {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoStartFrom
            } else {
                return startFrom
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.autoStartFrom = newValue
            }
            startFrom = newValue
        }
    }

    public var autoSkipLast: Int32 {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoSkipLast
            } else {
                return skipLast
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.autoSkipLast = newValue
            }
            skipLast = newValue
        }
    }

    public var podcastSortOrder: PodcastEpisodeSortOrder? {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.episodesSortOrder
            } else {
                return PodcastEpisodeSortOrder(rawValue: episodeSortOrder)
            }
        }
    }

    public var autoArchivePlayedAfterTime: TimeInterval {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoArchivePlayed.time.rawValue
            } else {
                return autoArchivePlayedAfter
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                if FeatureFlag.settingsSync.enabled {
                    if let time = AutoArchiveAfterTime(rawValue: newValue), let inactive = AutoArchiveAfterPlayed(time: time) {
                        settings.autoArchivePlayed = inactive
                    }
                }
            }
            autoArchivePlayedAfter = newValue
        }
    }

    public var autoArchiveInactiveAfterTime: TimeInterval {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoArchiveInactive.time.rawValue
            } else {
                return autoArchiveInactiveAfter
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                if let time = AutoArchiveAfterTime(rawValue: newValue), let inactive = AutoArchiveAfterInactive(time: time) {
                    settings.autoArchiveInactive = inactive
                }
            }
            autoArchiveInactiveAfter = newValue
        }
    }

    public var autoArchiveEpisodeLimitCount: Int32 {
        get {
            if FeatureFlag.settingsSync.enabled {
                return settings.autoArchiveEpisodeLimit
            } else {
                return autoArchiveEpisodeLimit
            }
        }
        set {
            if FeatureFlag.settingsSync.enabled {
                settings.autoArchiveEpisodeLimit = newValue
            }
            autoArchiveEpisodeLimit = newValue
        }
    }
}
