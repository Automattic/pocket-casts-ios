import Foundation
import GRDB

/// GRDB Record type representing the SJEpisode table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct EpisodeRecord: Codable, Identifiable {
    var id: Int64?
    var addedDate: Double?
    var lastDownloadAttemptDate: Double?
    var detailedDescription: String?
    var downloadErrorDetails: String?
    var downloadTaskId: String?
    var downloadUrl: String?
    var episodeDescription: String?
    var episodeStatus: Int32
    var fileType: String?
    var contentType: String?
    var keepEpisode: Bool
    var playedUpTo: Double
    var duration: Double
    var playingStatus: Int32
    var autoDownloadStatus: Int32
    var publishedDate: Double?
    var sizeInBytes: Int64
    var playingStatusModified: Int64
    var playedUpToModified: Int64
    var durationModified: Int64
    var keepEpisodeModified: Int64
    var title: String?
    var uuid: String
    var podcastUuid: String
    var playbackErrorDetails: String?
    var cachedFrameCount: Int64
    var lastPlaybackInteractionDate: Double?
    var lastPlaybackInteractionSyncStatus: Int32
    var podcast_id: Int64
    var episodeNumber: Int64
    var seasonNumber: Int64
    var episodeType: String?
    var archived: Bool
    var archivedModified: Int64
    var lastArchiveInteractionDate: Double?
    var excludeFromEpisodeLimit: Bool
    var starredModified: Int64
    var deselectedChapters: String?
    var deselectedChaptersModified: Int64
    var wasDeleted: Bool
    var metadata: String?

    /// Initializes a default EpisodeRecord with reasonable defaults
    init() {
        self.id = nil
        self.addedDate = nil
        self.lastDownloadAttemptDate = nil
        self.detailedDescription = nil
        self.downloadErrorDetails = nil
        self.downloadTaskId = nil
        self.downloadUrl = nil
        self.episodeDescription = nil
        self.episodeStatus = 0
        self.fileType = nil
        self.contentType = nil
        self.keepEpisode = false
        self.playedUpTo = 0
        self.duration = 0
        self.playingStatus = 0
        self.autoDownloadStatus = 0
        self.publishedDate = nil
        self.sizeInBytes = 0
        self.playingStatusModified = 0
        self.playedUpToModified = 0
        self.durationModified = 0
        self.keepEpisodeModified = 0
        self.title = nil
        self.uuid = ""
        self.podcastUuid = ""
        self.playbackErrorDetails = nil
        self.cachedFrameCount = 0
        self.lastPlaybackInteractionDate = nil
        self.lastPlaybackInteractionSyncStatus = 1
        self.podcast_id = 0
        self.episodeNumber = -1
        self.seasonNumber = -1
        self.episodeType = nil
        self.archived = false
        self.archivedModified = 0
        self.lastArchiveInteractionDate = nil
        self.excludeFromEpisodeLimit = false
        self.starredModified = 0
        self.deselectedChapters = nil
        self.deselectedChaptersModified = 0
        self.wasDeleted = false
        self.metadata = nil
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension EpisodeRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "SJEpisode"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension EpisodeRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let addedDate = Column(CodingKeys.addedDate)
        static let lastDownloadAttemptDate = Column(CodingKeys.lastDownloadAttemptDate)
        static let detailedDescription = Column(CodingKeys.detailedDescription)
        static let downloadErrorDetails = Column(CodingKeys.downloadErrorDetails)
        static let downloadTaskId = Column(CodingKeys.downloadTaskId)
        static let downloadUrl = Column(CodingKeys.downloadUrl)
        static let episodeDescription = Column(CodingKeys.episodeDescription)
        static let episodeStatus = Column(CodingKeys.episodeStatus)
        static let fileType = Column(CodingKeys.fileType)
        static let contentType = Column(CodingKeys.contentType)
        static let keepEpisode = Column(CodingKeys.keepEpisode)
        static let playedUpTo = Column(CodingKeys.playedUpTo)
        static let duration = Column(CodingKeys.duration)
        static let playingStatus = Column(CodingKeys.playingStatus)
        static let autoDownloadStatus = Column(CodingKeys.autoDownloadStatus)
        static let publishedDate = Column(CodingKeys.publishedDate)
        static let sizeInBytes = Column(CodingKeys.sizeInBytes)
        static let playingStatusModified = Column(CodingKeys.playingStatusModified)
        static let playedUpToModified = Column(CodingKeys.playedUpToModified)
        static let durationModified = Column(CodingKeys.durationModified)
        static let keepEpisodeModified = Column(CodingKeys.keepEpisodeModified)
        static let title = Column(CodingKeys.title)
        static let uuid = Column(CodingKeys.uuid)
        static let podcastUuid = Column(CodingKeys.podcastUuid)
        static let playbackErrorDetails = Column(CodingKeys.playbackErrorDetails)
        static let cachedFrameCount = Column(CodingKeys.cachedFrameCount)
        static let lastPlaybackInteractionDate = Column(CodingKeys.lastPlaybackInteractionDate)
        static let lastPlaybackInteractionSyncStatus = Column(CodingKeys.lastPlaybackInteractionSyncStatus)
        static let podcast_id = Column(CodingKeys.podcast_id)
        static let episodeNumber = Column(CodingKeys.episodeNumber)
        static let seasonNumber = Column(CodingKeys.seasonNumber)
        static let episodeType = Column(CodingKeys.episodeType)
        static let archived = Column(CodingKeys.archived)
        static let archivedModified = Column(CodingKeys.archivedModified)
        static let lastArchiveInteractionDate = Column(CodingKeys.lastArchiveInteractionDate)
        static let excludeFromEpisodeLimit = Column(CodingKeys.excludeFromEpisodeLimit)
        static let starredModified = Column(CodingKeys.starredModified)
        static let deselectedChapters = Column(CodingKeys.deselectedChapters)
        static let deselectedChaptersModified = Column(CodingKeys.deselectedChaptersModified)
        static let wasDeleted = Column(CodingKeys.wasDeleted)
        static let metadata = Column(CodingKeys.metadata)
    }
}

// MARK: - Associations

extension EpisodeRecord {
    /// Foreign key to the podcast this episode belongs to
    static let podcastForeignKey = ForeignKey(["podcast_id"])

    /// Association to the podcast this episode belongs to
    static let podcast = belongsTo(PodcastRecord.self, using: podcastForeignKey)
}
