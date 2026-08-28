import Foundation
import GRDB
import PocketCastsUtils

public class Episode: NSObject, BaseEpisode {
    private static let bonusType = "bonus"
    private static let trailerType = "trailer"

    @objc public var id = 0 as Int64
    @objc public var addedDate: Date?
    @objc public var lastDownloadAttemptDate: Date?
    @objc public var detailedDescription: String?
    @objc public var downloadErrorDetails: String?
    @objc public var downloadTaskId: String?
    @objc public var downloadUrl: String?
    @objc public var hlsUrl: String?
    @objc public var episodeDescription: String?
    @objc public var episodeStatus = 0 as Int32
    @objc public var fileType: String?
    @objc public var contentType: String?
    @objc public var keepEpisode = false
    @objc public var playedUpTo: Double = 0
    @objc public var duration: Double = 0
    @objc public var playingStatus = 0 as Int32
    @objc public var autoDownloadStatus = 0 as Int32
    @objc public var publishedDate: Date?
    @objc public var sizeInBytes = 0 as Int64
    @objc public var playingStatusModified = 0 as Int64
    @objc public var playedUpToModified = 0 as Int64
    @objc public var durationModified = 0 as Int64
    @objc public var keepEpisodeModified = 0 as Int64
    @objc public var starredModified = 0 as Int64
    @objc public var lastPlaybackInteractionDate: Date?
    @objc public var lastPlaybackInteractionSyncStatus = 1 as Int32
    @objc public var title: String?
    @objc public var uuid = ""
    @objc public var podcastUuid = ""
    @objc public var playbackErrorDetails: String?
    @objc public var cachedFrameCount = 0 as Int64
    @objc public var podcast_id = 0 as Int64
    @objc public var episodeNumber = -1 as Int64
    @objc public var seasonNumber = -1 as Int64
    @objc public var episodeType: String?
    @objc public var archived = false
    @objc public var archivedModified = 0 as Int64
    @objc public var lastArchiveInteractionDate: Date?
    @objc public var excludeFromEpisodeLimit = false
    @objc public var hasOnlyUuid = false
    @objc public var deselectedChapters: String?
    @objc public var deselectedChaptersModified = 0 as Int64
    @objc public var wasDeleted = false
    public var hasGeneratedTranscript: Bool? = nil

    public var hasBookmarks: Bool {
        // This wil cause a regression in which the bookmarks won't be displayed
        // for episodes with bookmarks.
        // However, this call is happening on the main thread and can block the whole app.
        // We will re-add this again in a way that's not a blocker
        //DataManager.sharedManager.bookmarks.bookmarkCount(forEpisode: uuid) > 0
        false
    }

    public var isUserEpisode: Bool {
        false
    }

    override public init() {}

    public func displayableTitle() -> String {
        title ?? ""
    }

    public func pathToDownloadedFile(pathFinder: FilePathProtocol) -> String {
        if downloaded(pathFinder: pathFinder) {
            return pathFinder.pathForEpisode(self)
        } else if bufferedForStreaming() {
            return pathFinder.streamingBufferPathForEpisode(self)
        }

        return pathToTempFile(pathFinder: pathFinder)
    }

    public func pathToTempFile(pathFinder: FilePathProtocol) -> String {
        pathFinder.tempPathForEpisode(self)
    }

    // MARK: - State

    public func downloaded(pathFinder: FilePathProtocol) -> Bool {
        if episodeStatus != DownloadStatus.downloaded.rawValue { return false }

        let path = pathFinder.pathForEpisode(self)

        return FileManager.default.fileExists(atPath: path)
    }

    public func streamDownloaded(pathFinder: FilePathProtocol) -> Bool {
        if episodeStatus != DownloadStatus.downloadedForStreaming.rawValue { return false }

        let path = pathFinder.streamingBufferPathForEpisode(self)

        return FileManager.default.fileExists(atPath: path)
    }

    public func bufferedForStreaming() -> Bool {
        episodeStatus == DownloadStatus.downloadedForStreaming.rawValue
    }

    public func downloadFailed() -> Bool {
        episodeStatus == DownloadStatus.downloadFailed.rawValue
    }

    public func downloading() -> Bool {
        episodeStatus == DownloadStatus.downloading.rawValue
    }

    public func queued() -> Bool {
        episodeStatus == DownloadStatus.queued.rawValue
    }

    public func waitingForWifi() -> Bool {
        episodeStatus == DownloadStatus.waitingForWifi.rawValue
    }

    public func inProgress() -> Bool {
        playingStatus == PlayingStatus.inProgress.rawValue
    }

    public func played() -> Bool {
        playingStatus == PlayingStatus.completed.rawValue
    }

    public func unplayed() -> Bool {
        playingStatus == PlayingStatus.notPlayed.rawValue
    }

    public func exemptFromAutoDownload() -> Bool {
        autoDownloadStatus == AutoDownloadStatus.userDeletedFile.rawValue || autoDownloadStatus == AutoDownloadStatus.userCancelledDownload.rawValue
    }

    public func playbackError() -> Bool {
        playbackErrorDetails != nil
    }

    public func isBonus() -> Bool {
        episodeType?.lowercased() == Episode.bonusType
    }

    public func isTrailer() -> Bool {
        episodeType?.lowercased() == Episode.trailerType
    }

    public func parentIdentifier() -> String {
        podcastUuid
    }

    // MARK: - Meta

    @objc public func videoPodcast() -> Bool {
        if let fileType, fileType.startsWith(string: "video/") {
            return true
        }

        return false
    }

    // MARK: - Helpers

    public func mayContainChapters() -> Bool {
        guard let fileType else { return false }

        return (fileType.caseInsensitiveCompare("audio/x-m4a") == .orderedSame ||
            fileType.caseInsensitiveCompare("audio/x-m4b") == .orderedSame ||
            fileType.caseInsensitiveCompare("audio/mp4") == .orderedSame ||
            fileType.caseInsensitiveCompare("audio/mp3") == .orderedSame ||
            fileType.caseInsensitiveCompare("audio/mpeg") == .orderedSame)
    }

    public func parentPodcast(dataManager: DataManager = .sharedManager) -> Podcast? {
        dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
    }

    public func taggableId() -> Int {
        Int(truncatingIfNeeded: id)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherEpisode = object as? Episode else { return false }

        return otherEpisode.uuid == uuid
    }

    override public var hash: Int {
        taggableId()
    }

    // MARK: - Metadata

    public struct Metadata: Decodable {
        public let showNotes: String?
        public let image: String?

        /// Podlove chapters
        public let chapters: [EpisodeChapter]?

        /// Podcast Index chapters
        public let chaptersUrl: String?

        public struct EpisodeChapter: Decodable {
            public let startTime: TimeInterval
            public let title: String?
            public let endTime: TimeInterval?
        }

        public let transcripts: [Transcript]
        public let pocketCastsTranscripts: [Transcript]?

        public struct Transcript: Decodable {
            public let url: String
            public let type: String
            public let language: String?

            public init(url: String, type: String, language: String?) {
                self.url = url
                self.type = type
                self.language = language
            }
        }
    }

    // MARK: - GRDB

    public static let databaseTableName = "SJEpisode"

    enum CodingKeys: String, CodingKey {
        case id
        case addedDate
        case lastDownloadAttemptDate
        case detailedDescription
        case downloadErrorDetails
        case downloadTaskId
        case downloadUrl
        case hlsUrl
        case episodeDescription
        case episodeStatus
        case fileType
        case contentType
        case keepEpisode
        case playedUpTo
        case duration
        case playingStatus
        case autoDownloadStatus
        case publishedDate
        case sizeInBytes
        case playingStatusModified
        case playedUpToModified
        case durationModified
        case keepEpisodeModified
        case starredModified
        case lastPlaybackInteractionDate
        case lastPlaybackInteractionSyncStatus
        case title
        case uuid
        case podcastUuid
        case playbackErrorDetails
        case cachedFrameCount
        case podcast_id
        case episodeNumber
        case seasonNumber
        case episodeType
        case archived
        case archivedModified
        case lastArchiveInteractionDate
        case excludeFromEpisodeLimit
        case deselectedChapters
        case deselectedChaptersModified
        case wasDeleted
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
        lastDownloadAttemptDate = try container.decodeIfPresent(Date.self, forKey: .lastDownloadAttemptDate)
        detailedDescription = try container.decodeIfPresent(String.self, forKey: .detailedDescription)
        downloadErrorDetails = try container.decodeIfPresent(String.self, forKey: .downloadErrorDetails)
        downloadTaskId = try container.decodeIfPresent(String.self, forKey: .downloadTaskId)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        hlsUrl = try container.decodeIfPresent(String.self, forKey: .hlsUrl)
        episodeDescription = try container.decodeIfPresent(String.self, forKey: .episodeDescription)
        episodeStatus = try container.decodeIfPresent(Int32.self, forKey: .episodeStatus) ?? 0
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        keepEpisode = try container.decodeIfPresent(Bool.self, forKey: .keepEpisode) ?? false
        playedUpTo = try container.decodeIfPresent(Double.self, forKey: .playedUpTo) ?? 0
        duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 0
        playingStatus = try container.decodeIfPresent(Int32.self, forKey: .playingStatus) ?? 0
        autoDownloadStatus = try container.decodeIfPresent(Int32.self, forKey: .autoDownloadStatus) ?? 0
        publishedDate = try container.decodeIfPresent(Date.self, forKey: .publishedDate)
        sizeInBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeInBytes) ?? 0
        playingStatusModified = try container.decodeIfPresent(Int64.self, forKey: .playingStatusModified) ?? 0
        playedUpToModified = try container.decodeIfPresent(Int64.self, forKey: .playedUpToModified) ?? 0
        durationModified = try container.decodeIfPresent(Int64.self, forKey: .durationModified) ?? 0
        keepEpisodeModified = try container.decodeIfPresent(Int64.self, forKey: .keepEpisodeModified) ?? 0
        starredModified = try container.decodeIfPresent(Int64.self, forKey: .starredModified) ?? 0
        lastPlaybackInteractionDate = try container.decodeIfPresent(Date.self, forKey: .lastPlaybackInteractionDate)
        lastPlaybackInteractionSyncStatus = try container.decodeIfPresent(Int32.self, forKey: .lastPlaybackInteractionSyncStatus) ?? 1
        title = try container.decodeIfPresent(String.self, forKey: .title)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        podcastUuid = try container.decodeIfPresent(String.self, forKey: .podcastUuid) ?? ""
        playbackErrorDetails = try container.decodeIfPresent(String.self, forKey: .playbackErrorDetails)
        cachedFrameCount = try container.decodeIfPresent(Int64.self, forKey: .cachedFrameCount) ?? 0
        podcast_id = try container.decodeIfPresent(Int64.self, forKey: .podcast_id) ?? 0
        episodeNumber = try container.decodeIfPresent(Int64.self, forKey: .episodeNumber) ?? -1
        seasonNumber = try container.decodeIfPresent(Int64.self, forKey: .seasonNumber) ?? -1
        episodeType = try container.decodeIfPresent(String.self, forKey: .episodeType)
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
        archivedModified = try container.decodeIfPresent(Int64.self, forKey: .archivedModified) ?? 0
        lastArchiveInteractionDate = try container.decodeIfPresent(Date.self, forKey: .lastArchiveInteractionDate)
        excludeFromEpisodeLimit = try container.decodeIfPresent(Bool.self, forKey: .excludeFromEpisodeLimit) ?? false
        deselectedChapters = try container.decodeIfPresent(String.self, forKey: .deselectedChapters)
        deselectedChaptersModified = try container.decodeIfPresent(Int64.self, forKey: .deselectedChaptersModified) ?? 0
        wasDeleted = try container.decodeIfPresent(Bool.self, forKey: .wasDeleted) ?? false
    }

    public func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["addedDate"] = addedDate?.timeIntervalSince1970
        container["lastDownloadAttemptDate"] = (lastDownloadAttemptDate ?? Date(timeIntervalSince1970: 0)).timeIntervalSince1970
        container["detailedDescription"] = detailedDescription
        container["downloadErrorDetails"] = downloadErrorDetails
        container["downloadTaskId"] = downloadTaskId
        container["downloadUrl"] = downloadUrl
        container["hlsUrl"] = hlsUrl
        container["episodeDescription"] = episodeDescription
        container["episodeStatus"] = episodeStatus
        container["fileType"] = fileType
        container["contentType"] = contentType
        container["keepEpisode"] = keepEpisode
        container["playedUpTo"] = playedUpTo
        container["duration"] = duration
        container["playingStatus"] = playingStatus
        container["autoDownloadStatus"] = autoDownloadStatus
        container["publishedDate"] = publishedDate?.timeIntervalSince1970
        container["sizeInBytes"] = sizeInBytes
        container["playingStatusModified"] = playingStatusModified
        container["playedUpToModified"] = playedUpToModified
        container["durationModified"] = durationModified
        container["keepEpisodeModified"] = keepEpisodeModified
        container["starredModified"] = starredModified
        container["lastPlaybackInteractionDate"] = lastPlaybackInteractionDate?.timeIntervalSince1970
        container["lastPlaybackInteractionSyncStatus"] = lastPlaybackInteractionSyncStatus
        container["title"] = title
        container["uuid"] = uuid
        container["podcastUuid"] = podcastUuid
        container["playbackErrorDetails"] = playbackErrorDetails
        container["cachedFrameCount"] = cachedFrameCount
        container["podcast_id"] = podcast_id
        container["episodeNumber"] = episodeNumber
        container["seasonNumber"] = seasonNumber
        container["episodeType"] = episodeType
        container["archived"] = archived
        container["archivedModified"] = archivedModified
        container["lastArchiveInteractionDate"] = (lastArchiveInteractionDate ?? Date(timeIntervalSince1970: 0)).timeIntervalSince1970
        container["excludeFromEpisodeLimit"] = excludeFromEpisodeLimit
        container["deselectedChapters"] = deselectedChapters
        container["deselectedChaptersModified"] = deselectedChaptersModified
        container["wasDeleted"] = wasDeleted
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let addedDate = Column(CodingKeys.addedDate)
        public static let lastDownloadAttemptDate = Column(CodingKeys.lastDownloadAttemptDate)
        public static let detailedDescription = Column(CodingKeys.detailedDescription)
        public static let downloadErrorDetails = Column(CodingKeys.downloadErrorDetails)
        public static let downloadTaskId = Column(CodingKeys.downloadTaskId)
        public static let downloadUrl = Column(CodingKeys.downloadUrl)
        public static let hlsUrl = Column(CodingKeys.hlsUrl)
        public static let episodeDescription = Column(CodingKeys.episodeDescription)
        public static let episodeStatus = Column(CodingKeys.episodeStatus)
        public static let fileType = Column(CodingKeys.fileType)
        public static let contentType = Column(CodingKeys.contentType)
        public static let keepEpisode = Column(CodingKeys.keepEpisode)
        public static let playedUpTo = Column(CodingKeys.playedUpTo)
        public static let duration = Column(CodingKeys.duration)
        public static let playingStatus = Column(CodingKeys.playingStatus)
        public static let autoDownloadStatus = Column(CodingKeys.autoDownloadStatus)
        public static let publishedDate = Column(CodingKeys.publishedDate)
        public static let sizeInBytes = Column(CodingKeys.sizeInBytes)
        public static let playingStatusModified = Column(CodingKeys.playingStatusModified)
        public static let playedUpToModified = Column(CodingKeys.playedUpToModified)
        public static let durationModified = Column(CodingKeys.durationModified)
        public static let keepEpisodeModified = Column(CodingKeys.keepEpisodeModified)
        public static let starredModified = Column(CodingKeys.starredModified)
        public static let lastPlaybackInteractionDate = Column(CodingKeys.lastPlaybackInteractionDate)
        public static let lastPlaybackInteractionSyncStatus = Column(CodingKeys.lastPlaybackInteractionSyncStatus)
        public static let title = Column(CodingKeys.title)
        public static let uuid = Column(CodingKeys.uuid)
        public static let podcastUuid = Column(CodingKeys.podcastUuid)
        public static let playbackErrorDetails = Column(CodingKeys.playbackErrorDetails)
        public static let cachedFrameCount = Column(CodingKeys.cachedFrameCount)
        public static let podcast_id = Column(CodingKeys.podcast_id)
        public static let episodeNumber = Column(CodingKeys.episodeNumber)
        public static let seasonNumber = Column(CodingKeys.seasonNumber)
        public static let episodeType = Column(CodingKeys.episodeType)
        public static let archived = Column(CodingKeys.archived)
        public static let archivedModified = Column(CodingKeys.archivedModified)
        public static let lastArchiveInteractionDate = Column(CodingKeys.lastArchiveInteractionDate)
        public static let excludeFromEpisodeLimit = Column(CodingKeys.excludeFromEpisodeLimit)
        public static let deselectedChapters = Column(CodingKeys.deselectedChapters)
        public static let deselectedChaptersModified = Column(CodingKeys.deselectedChaptersModified)
        public static let wasDeleted = Column(CodingKeys.wasDeleted)
    }
}

extension Episode: FetchableRecord, PersistableRecord, TableRecord, Decodable {}
