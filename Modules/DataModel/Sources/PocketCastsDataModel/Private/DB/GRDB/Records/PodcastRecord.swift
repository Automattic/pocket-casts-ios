import Foundation
import GRDB

/// GRDB Record type representing the SJPodcast table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PodcastRecord: Codable, Identifiable {
    var id: Int64?
    var addedDate: Double?
    var autoDownloadSetting: Int32
    var autoAddToUpNext: Int32
    var episodeKeepSetting: Int32
    var backgroundColor: String?
    var detailColor: String?
    var primaryColor: String?
    var secondaryColor: String?
    var lastColorDownloadDate: Double?
    var imageURL: String?
    var latestEpisodeUuid: String?
    var latestEpisodeDate: Double?
    var mediaType: String?
    var lastThumbnailDownloadDate: Double?
    var thumbnailStatus: Int32
    var podcastUrl: String?
    var author: String?
    var playbackSpeed: Double
    var boostVolume: Bool
    var trimSilenceAmount: Int32
    var podcastCategory: String?
    var podcastDescription: String?
    var podcastHTMLDescription: String?
    var sortOrder: Int32
    var startFrom: Int32
    var skipLast: Int32
    var subscribed: Int32
    var title: String?
    var uuid: String
    var syncStatus: Int32
    var colorVersion: Int32
    var pushEnabled: Bool
    var episodeSortOrder: Int32
    var showType: String?
    var estimatedNextEpisode: Double?
    var episodeFrequency: String?
    var lastUpdatedAt: String?
    var excludeFromAutoArchive: Bool
    var overrideGlobalEffects: Bool
    var overrideGlobalArchive: Bool
    var autoArchivePlayedAfter: Double
    var autoArchiveInactiveAfter: Double
    var episodeGrouping: Int32
    var isPaid: Bool
    var licensing: Int32
    var fullSyncLastSyncAt: String?
    var showArchived: Bool
    var refreshAvailable: Bool
    var folderUuid: String?
    var usedCustomEffectsBefore: Bool
    var isPrivate: Bool
    var fundingURL: String?
    var settings: String

    /// Initializes a default PodcastRecord with reasonable defaults
    init() {
        self.id = nil
        self.addedDate = nil
        self.autoDownloadSetting = 0
        self.autoAddToUpNext = 0
        self.episodeKeepSetting = 0
        self.backgroundColor = nil
        self.detailColor = nil
        self.primaryColor = nil
        self.secondaryColor = nil
        self.lastColorDownloadDate = nil
        self.imageURL = nil
        self.latestEpisodeUuid = nil
        self.latestEpisodeDate = nil
        self.mediaType = nil
        self.lastThumbnailDownloadDate = nil
        self.thumbnailStatus = 1
        self.podcastUrl = nil
        self.author = nil
        self.playbackSpeed = 1
        self.boostVolume = false
        self.trimSilenceAmount = 0
        self.podcastCategory = nil
        self.podcastDescription = nil
        self.podcastHTMLDescription = nil
        self.sortOrder = 0
        self.startFrom = 0
        self.skipLast = 0
        self.subscribed = 1
        self.title = nil
        self.uuid = ""
        self.syncStatus = 0
        self.colorVersion = 1
        self.pushEnabled = false
        self.episodeSortOrder = 1
        self.showType = nil
        self.estimatedNextEpisode = nil
        self.episodeFrequency = nil
        self.lastUpdatedAt = nil
        self.excludeFromAutoArchive = false
        self.overrideGlobalEffects = false
        self.overrideGlobalArchive = false
        self.autoArchivePlayedAfter = 0
        self.autoArchiveInactiveAfter = 0
        self.episodeGrouping = 0
        self.isPaid = false
        self.licensing = 0
        self.fullSyncLastSyncAt = nil
        self.showArchived = false
        self.refreshAvailable = false
        self.folderUuid = nil
        self.usedCustomEffectsBefore = false
        self.isPrivate = false
        self.fundingURL = nil
        self.settings = ""
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension PodcastRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "SJPodcast"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension PodcastRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let addedDate = Column(CodingKeys.addedDate)
        static let autoDownloadSetting = Column(CodingKeys.autoDownloadSetting)
        static let autoAddToUpNext = Column(CodingKeys.autoAddToUpNext)
        static let episodeKeepSetting = Column(CodingKeys.episodeKeepSetting)
        static let backgroundColor = Column(CodingKeys.backgroundColor)
        static let detailColor = Column(CodingKeys.detailColor)
        static let primaryColor = Column(CodingKeys.primaryColor)
        static let secondaryColor = Column(CodingKeys.secondaryColor)
        static let lastColorDownloadDate = Column(CodingKeys.lastColorDownloadDate)
        static let imageURL = Column(CodingKeys.imageURL)
        static let latestEpisodeUuid = Column(CodingKeys.latestEpisodeUuid)
        static let latestEpisodeDate = Column(CodingKeys.latestEpisodeDate)
        static let mediaType = Column(CodingKeys.mediaType)
        static let lastThumbnailDownloadDate = Column(CodingKeys.lastThumbnailDownloadDate)
        static let thumbnailStatus = Column(CodingKeys.thumbnailStatus)
        static let podcastUrl = Column(CodingKeys.podcastUrl)
        static let author = Column(CodingKeys.author)
        static let playbackSpeed = Column(CodingKeys.playbackSpeed)
        static let boostVolume = Column(CodingKeys.boostVolume)
        static let trimSilenceAmount = Column(CodingKeys.trimSilenceAmount)
        static let podcastCategory = Column(CodingKeys.podcastCategory)
        static let podcastDescription = Column(CodingKeys.podcastDescription)
        static let podcastHTMLDescription = Column(CodingKeys.podcastHTMLDescription)
        static let sortOrder = Column(CodingKeys.sortOrder)
        static let startFrom = Column(CodingKeys.startFrom)
        static let skipLast = Column(CodingKeys.skipLast)
        static let subscribed = Column(CodingKeys.subscribed)
        static let title = Column(CodingKeys.title)
        static let uuid = Column(CodingKeys.uuid)
        static let syncStatus = Column(CodingKeys.syncStatus)
        static let colorVersion = Column(CodingKeys.colorVersion)
        static let pushEnabled = Column(CodingKeys.pushEnabled)
        static let episodeSortOrder = Column(CodingKeys.episodeSortOrder)
        static let showType = Column(CodingKeys.showType)
        static let estimatedNextEpisode = Column(CodingKeys.estimatedNextEpisode)
        static let episodeFrequency = Column(CodingKeys.episodeFrequency)
        static let lastUpdatedAt = Column(CodingKeys.lastUpdatedAt)
        static let excludeFromAutoArchive = Column(CodingKeys.excludeFromAutoArchive)
        static let overrideGlobalEffects = Column(CodingKeys.overrideGlobalEffects)
        static let overrideGlobalArchive = Column(CodingKeys.overrideGlobalArchive)
        static let autoArchivePlayedAfter = Column(CodingKeys.autoArchivePlayedAfter)
        static let autoArchiveInactiveAfter = Column(CodingKeys.autoArchiveInactiveAfter)
        static let episodeGrouping = Column(CodingKeys.episodeGrouping)
        static let isPaid = Column(CodingKeys.isPaid)
        static let licensing = Column(CodingKeys.licensing)
        static let fullSyncLastSyncAt = Column(CodingKeys.fullSyncLastSyncAt)
        static let showArchived = Column(CodingKeys.showArchived)
        static let refreshAvailable = Column(CodingKeys.refreshAvailable)
        static let folderUuid = Column(CodingKeys.folderUuid)
        static let usedCustomEffectsBefore = Column(CodingKeys.usedCustomEffectsBefore)
        static let isPrivate = Column(CodingKeys.isPrivate)
        static let fundingURL = Column(CodingKeys.fundingURL)
        static let settings = Column(CodingKeys.settings)
    }
}

// MARK: - Associations

extension PodcastRecord {
    /// Association to episodes belonging to this podcast
    static let episodes = hasMany(EpisodeRecord.self, using: EpisodeRecord.podcastForeignKey)
}
