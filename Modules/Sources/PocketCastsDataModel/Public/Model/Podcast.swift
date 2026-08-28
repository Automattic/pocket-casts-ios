import Foundation
import GRDB
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
    @objc public var podcastHTMLDescription: String?
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
    @objc public var isPrivate = false
    @objc public var isExplicit = false
    @objc public var fundingURL: String?

    public var settings = PodcastSettings.defaults

    // transient not saved to database
    public var cachedUnreadCount = 0

    // if set to an episode UUID, all podcast episodes after the given
    // UUID will be updated
    public var forceRefreshEpisodeFrom: String? = nil

    // transient not saved to database
    public var networkList: PodcastNetworkList? = nil

    override public init() {}

    public func autoDownloadOn() -> Bool {
        autoDownloadSetting == AutoDownloadSetting.latest.rawValue
    }

    public func autoAddToUpNextOn() -> Bool {
        autoAddToUpNext == AutoAddToUpNextSetting.addLast.rawValue || autoAddToUpNext == AutoAddToUpNextSetting.addFirst.rawValue
    }

    public func autoAddToUpNextSetting() -> AutoAddToUpNextSetting? {
        AutoAddToUpNextSetting(rawValue: autoAddToUpNext)
    }

    public func setAutoAddToUpNext(setting: AutoAddToUpNextSetting) {
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

    // MARK: - GRDB

    public static let databaseTableName = "SJPodcast"

    enum CodingKeys: String, CodingKey {
        case id
        case addedDate
        case autoDownloadSetting
        case autoAddToUpNext
        case autoArchiveEpisodeLimit = "episodeKeepSetting"
        case backgroundColor
        case detailColor
        case primaryColor
        case secondaryColor
        case lastColorDownloadDate
        case imageURL
        case latestEpisodeUuid
        case latestEpisodeDate
        case mediaType
        case lastThumbnailDownloadDate
        case thumbnailStatus
        case podcastUrl
        case author
        case overrideGlobalEffects
        case playbackSpeed
        case boostVolume
        case trimSilenceAmount
        case podcastCategory
        case podcastDescription
        case podcastHTMLDescription
        case sortOrder
        case startFrom
        case skipLast
        case subscribed
        case title
        case uuid
        case syncStatus
        case colorVersion
        case pushEnabled
        case episodeSortOrder
        case episodeGrouping
        case showType
        case estimatedNextEpisode
        case episodeFrequency
        case lastUpdatedAt
        case excludeFromAutoArchive
        case overrideGlobalArchive
        case autoArchivePlayedAfter
        case autoArchiveInactiveAfter
        case isPaid
        case licensing
        case fullSyncLastSyncAt
        case showArchived
        case refreshAvailable
        case folderUuid
        case usedCustomEffectsBefore
        case isPrivate
        case isExplicit
        case fundingURL
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
        autoDownloadSetting = try container.decodeIfPresent(Int32.self, forKey: .autoDownloadSetting) ?? 0
        autoAddToUpNext = try container.decodeIfPresent(Int32.self, forKey: .autoAddToUpNext) ?? 0
        autoArchiveEpisodeLimit = try container.decodeIfPresent(Int32.self, forKey: .autoArchiveEpisodeLimit) ?? 0
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        detailColor = try container.decodeIfPresent(String.self, forKey: .detailColor)
        primaryColor = try container.decodeIfPresent(String.self, forKey: .primaryColor)
        secondaryColor = try container.decodeIfPresent(String.self, forKey: .secondaryColor)
        lastColorDownloadDate = try container.decodeIfPresent(Date.self, forKey: .lastColorDownloadDate)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        latestEpisodeUuid = try container.decodeIfPresent(String.self, forKey: .latestEpisodeUuid)
        latestEpisodeDate = try container.decodeIfPresent(Date.self, forKey: .latestEpisodeDate)
        mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType)
        lastThumbnailDownloadDate = try container.decodeIfPresent(Date.self, forKey: .lastThumbnailDownloadDate)
        thumbnailStatus = try container.decodeIfPresent(Int32.self, forKey: .thumbnailStatus) ?? 1
        podcastUrl = try container.decodeIfPresent(String.self, forKey: .podcastUrl)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        overrideGlobalEffects = try container.decodeIfPresent(Bool.self, forKey: .overrideGlobalEffects) ?? false
        playbackSpeed = try container.decodeIfPresent(Double.self, forKey: .playbackSpeed) ?? 1
        boostVolume = try container.decodeIfPresent(Bool.self, forKey: .boostVolume) ?? false
        trimSilenceAmount = try container.decodeIfPresent(Int32.self, forKey: .trimSilenceAmount) ?? 0
        podcastCategory = try container.decodeIfPresent(String.self, forKey: .podcastCategory)
        podcastDescription = try container.decodeIfPresent(String.self, forKey: .podcastDescription)
        podcastHTMLDescription = try container.decodeIfPresent(String.self, forKey: .podcastHTMLDescription)
        sortOrder = try container.decodeIfPresent(Int32.self, forKey: .sortOrder) ?? 0
        startFrom = try container.decodeIfPresent(Int32.self, forKey: .startFrom) ?? 0
        skipLast = try container.decodeIfPresent(Int32.self, forKey: .skipLast) ?? 0
        subscribed = try container.decodeIfPresent(Int32.self, forKey: .subscribed) ?? 1
        title = try container.decodeIfPresent(String.self, forKey: .title)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        syncStatus = try container.decodeIfPresent(Int32.self, forKey: .syncStatus) ?? 0
        colorVersion = try container.decodeIfPresent(Int32.self, forKey: .colorVersion) ?? 1
        pushEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushEnabled) ?? false
        episodeSortOrder = try container.decodeIfPresent(Int32.self, forKey: .episodeSortOrder) ?? 1
        episodeGrouping = try container.decodeIfPresent(Int32.self, forKey: .episodeGrouping) ?? 0
        showType = try container.decodeIfPresent(String.self, forKey: .showType)
        estimatedNextEpisode = try container.decodeIfPresent(Date.self, forKey: .estimatedNextEpisode)
        episodeFrequency = try container.decodeIfPresent(String.self, forKey: .episodeFrequency)
        lastUpdatedAt = try container.decodeIfPresent(String.self, forKey: .lastUpdatedAt)
        excludeFromAutoArchive = try container.decodeIfPresent(Bool.self, forKey: .excludeFromAutoArchive) ?? false
        overrideGlobalArchive = try container.decodeIfPresent(Bool.self, forKey: .overrideGlobalArchive) ?? false
        autoArchivePlayedAfter = try container.decodeIfPresent(Double.self, forKey: .autoArchivePlayedAfter) ?? 0
        autoArchiveInactiveAfter = try container.decodeIfPresent(Double.self, forKey: .autoArchiveInactiveAfter) ?? 0
        isPaid = try container.decodeIfPresent(Bool.self, forKey: .isPaid) ?? false
        licensing = try container.decodeIfPresent(Int32.self, forKey: .licensing) ?? 0
        fullSyncLastSyncAt = try container.decodeIfPresent(String.self, forKey: .fullSyncLastSyncAt)
        showArchived = try container.decodeIfPresent(Bool.self, forKey: .showArchived) ?? false
        refreshAvailable = try container.decodeIfPresent(Bool.self, forKey: .refreshAvailable) ?? false
        folderUuid = try container.decodeIfPresent(String.self, forKey: .folderUuid)
        usedCustomEffectsBefore = try container.decodeIfPresent(Bool.self, forKey: .usedCustomEffectsBefore) ?? false
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        isExplicit = try container.decodeIfPresent(Bool.self, forKey: .isExplicit) ?? false
        fundingURL = try container.decodeIfPresent(String.self, forKey: .fundingURL)
    }

    public func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["addedDate"] = addedDate?.timeIntervalSince1970
        container["autoDownloadSetting"] = autoDownloadSetting
        container["autoAddToUpNext"] = autoAddToUpNext
        container["episodeKeepSetting"] = autoArchiveEpisodeLimit
        container["backgroundColor"] = backgroundColor
        container["detailColor"] = detailColor
        container["primaryColor"] = primaryColor
        container["secondaryColor"] = secondaryColor
        container["lastColorDownloadDate"] = lastColorDownloadDate?.timeIntervalSince1970
        container["imageURL"] = imageURL
        container["latestEpisodeUuid"] = latestEpisodeUuid
        container["latestEpisodeDate"] = latestEpisodeDate?.timeIntervalSince1970
        container["mediaType"] = mediaType
        container["lastThumbnailDownloadDate"] = lastThumbnailDownloadDate?.timeIntervalSince1970
        container["thumbnailStatus"] = thumbnailStatus
        container["podcastUrl"] = podcastUrl
        container["author"] = author
        container["overrideGlobalEffects"] = overrideGlobalEffects
        container["playbackSpeed"] = playbackSpeed
        container["boostVolume"] = boostVolume
        container["trimSilenceAmount"] = trimSilenceAmount
        container["podcastCategory"] = podcastCategory
        container["podcastDescription"] = podcastDescription
        container["podcastHTMLDescription"] = podcastHTMLDescription
        container["sortOrder"] = sortOrder
        container["startFrom"] = startFrom
        container["skipLast"] = skipLast
        container["subscribed"] = subscribed
        container["title"] = title
        container["uuid"] = uuid
        container["syncStatus"] = syncStatus
        container["colorVersion"] = colorVersion
        container["pushEnabled"] = pushEnabled
        container["episodeSortOrder"] = episodeSortOrder
        container["episodeGrouping"] = episodeGrouping
        container["showType"] = showType
        container["estimatedNextEpisode"] = estimatedNextEpisode?.timeIntervalSince1970
        container["episodeFrequency"] = episodeFrequency
        container["lastUpdatedAt"] = lastUpdatedAt
        container["excludeFromAutoArchive"] = excludeFromAutoArchive
        container["overrideGlobalArchive"] = overrideGlobalArchive
        container["autoArchivePlayedAfter"] = autoArchivePlayedAfter
        container["autoArchiveInactiveAfter"] = autoArchiveInactiveAfter
        container["isPaid"] = isPaid
        container["licensing"] = licensing
        container["fullSyncLastSyncAt"] = fullSyncLastSyncAt
        container["showArchived"] = showArchived
        container["refreshAvailable"] = refreshAvailable
        container["folderUuid"] = folderUuid
        container["usedCustomEffectsBefore"] = usedCustomEffectsBefore
        container["isPrivate"] = isPrivate
        container["isExplicit"] = isExplicit
        container["fundingURL"] = fundingURL
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let addedDate = Column(CodingKeys.addedDate)
        public static let autoDownloadSetting = Column(CodingKeys.autoDownloadSetting)
        public static let autoAddToUpNext = Column(CodingKeys.autoAddToUpNext)
        public static let autoArchiveEpisodeLimit = Column(CodingKeys.autoArchiveEpisodeLimit)
        public static let backgroundColor = Column(CodingKeys.backgroundColor)
        public static let detailColor = Column(CodingKeys.detailColor)
        public static let primaryColor = Column(CodingKeys.primaryColor)
        public static let secondaryColor = Column(CodingKeys.secondaryColor)
        public static let lastColorDownloadDate = Column(CodingKeys.lastColorDownloadDate)
        public static let imageURL = Column(CodingKeys.imageURL)
        public static let latestEpisodeUuid = Column(CodingKeys.latestEpisodeUuid)
        public static let latestEpisodeDate = Column(CodingKeys.latestEpisodeDate)
        public static let mediaType = Column(CodingKeys.mediaType)
        public static let lastThumbnailDownloadDate = Column(CodingKeys.lastThumbnailDownloadDate)
        public static let thumbnailStatus = Column(CodingKeys.thumbnailStatus)
        public static let podcastUrl = Column(CodingKeys.podcastUrl)
        public static let author = Column(CodingKeys.author)
        public static let overrideGlobalEffects = Column(CodingKeys.overrideGlobalEffects)
        public static let playbackSpeed = Column(CodingKeys.playbackSpeed)
        public static let boostVolume = Column(CodingKeys.boostVolume)
        public static let trimSilenceAmount = Column(CodingKeys.trimSilenceAmount)
        public static let podcastCategory = Column(CodingKeys.podcastCategory)
        public static let podcastDescription = Column(CodingKeys.podcastDescription)
        public static let podcastHTMLDescription = Column(CodingKeys.podcastHTMLDescription)
        public static let sortOrder = Column(CodingKeys.sortOrder)
        public static let startFrom = Column(CodingKeys.startFrom)
        public static let skipLast = Column(CodingKeys.skipLast)
        public static let subscribed = Column(CodingKeys.subscribed)
        public static let title = Column(CodingKeys.title)
        public static let uuid = Column(CodingKeys.uuid)
        public static let syncStatus = Column(CodingKeys.syncStatus)
        public static let colorVersion = Column(CodingKeys.colorVersion)
        public static let pushEnabled = Column(CodingKeys.pushEnabled)
        public static let episodeSortOrder = Column(CodingKeys.episodeSortOrder)
        public static let episodeGrouping = Column(CodingKeys.episodeGrouping)
        public static let showType = Column(CodingKeys.showType)
        public static let estimatedNextEpisode = Column(CodingKeys.estimatedNextEpisode)
        public static let episodeFrequency = Column(CodingKeys.episodeFrequency)
        public static let lastUpdatedAt = Column(CodingKeys.lastUpdatedAt)
        public static let excludeFromAutoArchive = Column(CodingKeys.excludeFromAutoArchive)
        public static let overrideGlobalArchive = Column(CodingKeys.overrideGlobalArchive)
        public static let autoArchivePlayedAfter = Column(CodingKeys.autoArchivePlayedAfter)
        public static let autoArchiveInactiveAfter = Column(CodingKeys.autoArchiveInactiveAfter)
        public static let isPaid = Column(CodingKeys.isPaid)
        public static let licensing = Column(CodingKeys.licensing)
        public static let fullSyncLastSyncAt = Column(CodingKeys.fullSyncLastSyncAt)
        public static let showArchived = Column(CodingKeys.showArchived)
        public static let refreshAvailable = Column(CodingKeys.refreshAvailable)
        public static let folderUuid = Column(CodingKeys.folderUuid)
        public static let usedCustomEffectsBefore = Column(CodingKeys.usedCustomEffectsBefore)
        public static let isPrivate = Column(CodingKeys.isPrivate)
        public static let isExplicit = Column(CodingKeys.isExplicit)
        public static let fundingURL = Column(CodingKeys.fundingURL)
    }
}

extension Podcast: FetchableRecord, PersistableRecord, TableRecord, Decodable {}

public enum TrimSilenceAmount: Int32, Codable, CaseIterable {
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
    override public var debugDescription: String {
        "Podcast: \(uuid) - \(title ?? "missing title")"
    }
}
