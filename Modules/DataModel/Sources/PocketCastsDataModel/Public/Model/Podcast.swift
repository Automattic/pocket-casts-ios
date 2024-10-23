import Foundation
import PocketCastsUtils

public class Podcast: NSObject, Identifiable {
    @objc public var id = 0 as Int64
    @objc public var addedDate: Date?
    @objc public var autoDownloadSetting = 0 as Int32
    @objc public var autoAddToUpNext = 0 as Int32
    @objc public var autoArchiveEpisodeLimit = 0 as Int32
    @objc public var backgroundColor: String?
    @objc public var detailColor: String? // dark artwork overlay
    @objc public var primaryColor: String? // light tint
    @objc public var secondaryColor: String? // dark tint
    @objc public var lastColorDownloadDate: Date?
    @objc public var imageURL: String?
    @objc public var latestEpisodeUuid: String?
    @objc public var latestEpisodeDate: Date?
    @objc public var mediaType: String?
    @objc public var lastThumbnailDownloadDate: Date?
    @objc public var thumbnailStatus = 1 as Int32
    @objc public var podcastUrl: String?
    @objc public var author: String?
    @objc public var overrideGlobalEffects = false
    @objc public var playbackSpeed = 1 as Double
    @objc public var boostVolume = false
    @objc public var trimSilenceAmount = 0 as Int32
    @objc public var podcastCategory: String?
    @objc public var podcastDescription: String?
    @objc public var sortOrder = 0 as Int32
    @objc public var startFrom = 0 as Int32
    @objc public var skipLast = 0 as Int32
    @objc public var subscribed = 1 as Int32
    @objc public var title: String?
    @objc public var uuid = ""
    @objc public var syncStatus = 0 as Int32
    @objc public var colorVersion = 1 as Int32
    @objc public var pushEnabled = false
    @objc public var episodeSortOrder = 1 as Int32
    @objc public var episodeGrouping = 0 as Int32
    @objc public var showType: String?
    @objc public var estimatedNextEpisode: Date?
    @objc public var episodeFrequency: String?
    @objc public var lastUpdatedAt: String?
    @objc public var excludeFromAutoArchive = false // we no longer use this setting, but it's here for migrations, etc
    @objc public var overrideGlobalArchive = false
    @objc public var autoArchivePlayedAfter = 0 as Double
    @objc public var autoArchiveInactiveAfter = 0 as Double
    @objc public var isPaid = false
    @objc public var licensing = 0 as Int32
    @objc public var fullSyncLastSyncAt: String?
    @objc public var showArchived = false
    @objc public var refreshAvailable = false
    @objc public var folderUuid: String?
    @objc public var usedCustomEffectsBefore = false

    public var settings: PodcastSettings = PodcastSettings.defaults

    // transient not saved to database
    public var cachedUnreadCount = 0

    // if set to an episode UUID, all podcast episodes after the given
    // UUID will be updated
    public var forceRefreshEpisodeFrom: String? = nil

    public func autoDownloadOn() -> Bool {
        autoDownloadSetting == AutoDownloadSetting.latest.rawValue
    }

    public func autoAddToUpNextOn() -> Bool {
        if FeatureFlag.newSettingsStorage.enabled {
            return settings.addToUpNext
        } else {
            return autoAddToUpNext == AutoAddToUpNextSetting.addLast.rawValue || autoAddToUpNext == AutoAddToUpNextSetting.addFirst.rawValue
        }
    }

    public func autoAddToUpNextSetting() -> AutoAddToUpNextSetting? {
        if FeatureFlag.newSettingsStorage.enabled {
            if settings.addToUpNext {
                switch settings.addToUpNextPosition {
                case .top:
                    return .addFirst
                case .bottom:
                    return .addLast
                }
            } else {
                return .off
            }
        } else {
            return AutoAddToUpNextSetting(rawValue: autoAddToUpNext)
        }
    }

    public func setAutoAddToUpNext(setting: AutoAddToUpNextSetting) {
        if FeatureFlag.newSettingsStorage.enabled {
            settings.addToUpNext = setting != .off
            settings.addToUpNextPosition = setting == .addFirst ? .top : .bottom
        }
        autoAddToUpNext = setting.rawValue
    }

    public func latestEpisode() -> Episode? {
        DataManager.sharedManager.findLatestEpisode(podcast: self)
    }

    public func latestEpisodes(limit: Int = 1) -> [Episode] {
        DataManager.sharedManager.findLatestEpisodes(podcast: self, limit: limit)
    }

    public func isSubscribed() -> Bool {
        subscribed != 0
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherPodcast = object as? Podcast else { return false }

        return otherPodcast.uuid == uuid
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: id)
    }

    public static func previewPodcast() -> Podcast {
        let podcast = Podcast()
        podcast.title = "The Greatest Podcast In The History Of Podcasts"
        podcast.author = "John Citizen Network Productions"
        podcast.uuid = "8a778760-a1de-0138-e66a-0acc26574db2"

        return podcast
    }
}

public enum TrimSilenceAmount: Int32, Codable {
    case off = 0, low = 3, medium = 5, high = 10
}

extension TrimSilence {
    public init(amount: TrimSilenceAmount) {
        switch amount {
        case .off:
            self = .off
        case .low:
            self = .mild
        case .medium:
            self = .medium
        case .high:
            self = .madMax
        }
    }

    public var amount: TrimSilenceAmount {
        switch self {
        case .off:
            return .off
        case .mild:
            return .low
        case .medium:
            return .medium
        case .madMax:
            return .high
        }
    }
}

extension Podcast {
    public override var debugDescription: String {
        "Podcast: \(uuid) - \(title ?? "missing title")"
    }
}
