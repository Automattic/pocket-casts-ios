import Foundation
import GRDB

/// GRDB Record type representing the SJUserEpisode table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct UserEpisodeRecord: Codable, Identifiable {
    var id: Int64?
    var addedDate: Double?
    var lastDownloadAttemptDate: Double?
    var downloadErrorDetails: String?
    var downloadTaskId: String?
    var downloadUrl: String?
    var episodeStatus: Int32
    var fileType: String?
    var contentType: String?
    var playedUpTo: Double
    var duration: Double
    var playingStatus: Int32
    var autoDownloadStatus: Int32
    var publishedDate: Double?
    var sizeInBytes: Int64
    var playingStatusModified: Int64
    var playedUpToModified: Int64
    var title: String?
    var uuid: String
    var playbackErrorDetails: String?
    var cachedFrameCount: Int64
    var imageUrl: String?
    var uploadStatus: Int32
    var uploadTaskId: String?
    var imageColor: Int32
    var titleModified: Int64
    var imageColorModified: Int64
    var imageModified: Int64
    var durationModified: Int64
    var hasCustomImage: Bool

    /// Initializes a default UserEpisodeRecord with reasonable defaults
    init() {
        self.id = nil
        self.addedDate = nil
        self.lastDownloadAttemptDate = nil
        self.downloadErrorDetails = nil
        self.downloadTaskId = nil
        self.downloadUrl = nil
        self.episodeStatus = 0
        self.fileType = nil
        self.contentType = nil
        self.playedUpTo = 0
        self.duration = 0
        self.playingStatus = 0
        self.autoDownloadStatus = 0
        self.publishedDate = nil
        self.sizeInBytes = 0
        self.playingStatusModified = 0
        self.playedUpToModified = 0
        self.title = nil
        self.uuid = ""
        self.playbackErrorDetails = nil
        self.cachedFrameCount = 0
        self.imageUrl = nil
        self.uploadStatus = 0
        self.uploadTaskId = nil
        self.imageColor = 0
        self.titleModified = 0
        self.imageColorModified = 0
        self.imageModified = 0
        self.durationModified = 0
        self.hasCustomImage = false
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension UserEpisodeRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "SJUserEpisode"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension UserEpisodeRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let addedDate = Column(CodingKeys.addedDate)
        static let lastDownloadAttemptDate = Column(CodingKeys.lastDownloadAttemptDate)
        static let downloadErrorDetails = Column(CodingKeys.downloadErrorDetails)
        static let downloadTaskId = Column(CodingKeys.downloadTaskId)
        static let downloadUrl = Column(CodingKeys.downloadUrl)
        static let episodeStatus = Column(CodingKeys.episodeStatus)
        static let fileType = Column(CodingKeys.fileType)
        static let contentType = Column(CodingKeys.contentType)
        static let playedUpTo = Column(CodingKeys.playedUpTo)
        static let duration = Column(CodingKeys.duration)
        static let playingStatus = Column(CodingKeys.playingStatus)
        static let autoDownloadStatus = Column(CodingKeys.autoDownloadStatus)
        static let publishedDate = Column(CodingKeys.publishedDate)
        static let sizeInBytes = Column(CodingKeys.sizeInBytes)
        static let playingStatusModified = Column(CodingKeys.playingStatusModified)
        static let playedUpToModified = Column(CodingKeys.playedUpToModified)
        static let title = Column(CodingKeys.title)
        static let uuid = Column(CodingKeys.uuid)
        static let playbackErrorDetails = Column(CodingKeys.playbackErrorDetails)
        static let cachedFrameCount = Column(CodingKeys.cachedFrameCount)
        static let imageUrl = Column(CodingKeys.imageUrl)
        static let uploadStatus = Column(CodingKeys.uploadStatus)
        static let uploadTaskId = Column(CodingKeys.uploadTaskId)
        static let imageColor = Column(CodingKeys.imageColor)
        static let titleModified = Column(CodingKeys.titleModified)
        static let imageColorModified = Column(CodingKeys.imageColorModified)
        static let imageModified = Column(CodingKeys.imageModified)
        static let durationModified = Column(CodingKeys.durationModified)
        static let hasCustomImage = Column(CodingKeys.hasCustomImage)
    }
}
