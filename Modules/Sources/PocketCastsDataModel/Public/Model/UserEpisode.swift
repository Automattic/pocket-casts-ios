import Foundation
import GRDB

public class UserEpisode: NSObject, BaseEpisode {
    @objc public var id = 0 as Int64
    @objc public var addedDate: Date?
    @objc public var lastDownloadAttemptDate: Date?
    @objc public var downloadErrorDetails: String?
    @objc public var downloadTaskId: String?
    @objc public var downloadUrl: String?
    @objc public var episodeStatus = 0 as Int32
    @objc public var fileType: String?
    // Note: contentType is saved separately via saveContentType() method.
    // The legacy SQL code doesn't include it in columnNames, so we ignore it for GRDB compatibility.
    @objc public var contentType: String?
    @objc public var playedUpTo: Double = 0
    @objc public var duration: Double = 0
    @objc public var durationModified = 0 as Int64
    @objc public var playingStatus = 1 as Int32
    @objc public var autoDownloadStatus = 0 as Int32
    @objc public var publishedDate: Date?
    @objc public var sizeInBytes = 0 as Int64
    @objc public var playingStatusModified = 0 as Int64
    @objc public var playedUpToModified = 0 as Int64
    @objc public var title: String?
    @objc public var titleModified = 0 as Int64
    @objc public var uuid = ""
    @objc public var playbackErrorDetails: String?
    @objc public var cachedFrameCount = 0 as Int64
    @objc public var uploadStatus = 0 as Int32
    @objc public var uploadTaskId: String?
    @objc public var imageUrl: String?
    @objc public var imageModified = 0 as Int64
    @objc public var imageColor = 0 as Int32
    @objc public var imageColorModified = 0 as Int64
    @objc public var hasCustomImage = false
    @objc public var hasOnlyUuid = false
    // Note: These properties exist on the model but were never added to the SJUserEpisode table.
    // The legacy SQL code doesn't persist them, so we ignore them for GRDB compatibility.
    @objc public var deselectedChapters: String?
    @objc public var deselectedChaptersModified = 0 as Int64

    // UserEpisode's are never archived or starred
    public var archived = false
    public var keepEpisode = false
    public var wasDeleted = false

    public var hasBookmarks: Bool {
        DataManager.sharedManager.bookmarks.bookmarkCount(forEpisode: uuid) > 0
    }

    public var isUserEpisode: Bool {
        true
    }

    override public init() {}

    public func displayableTitle() -> String {
        title ?? ""
    }

    public func parentIdentifier() -> String {
        DataConstants.userEpisodeFakePodcastId
    }

    public func jumpToOnStart() -> TimeInterval {
        0
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

    @objc public func videoPodcast() -> Bool {
        if let fileType, fileType.startsWith(string: "video/") {
            return true
        }

        return false
    }

    public func mayContainChapters() -> Bool {
        guard let fileType else { return false }

        return (fileType.caseInsensitiveCompare("audio/x-m4a") == .orderedSame || fileType.caseInsensitiveCompare("audio/x-m4b") == .orderedSame || fileType.caseInsensitiveCompare("audio/mp3") == .orderedSame || fileType.caseInsensitiveCompare("audio/mpeg") == .orderedSame)
    }

    public func taggableId() -> Int {
        Int(truncatingIfNeeded: id)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherEpisode = object as? UserEpisode else { return false }

        return otherEpisode.uuid == uuid
    }

    override public var hash: Int {
        taggableId()
    }

    public func uploaded() -> Bool {
        uploadStatus == UploadStatus.uploaded.rawValue
    }

    public func uploadFailed() -> Bool {
        uploadStatus == UploadStatus.uploadFailed.rawValue
    }

    public func uploading() -> Bool {
        uploadStatus == UploadStatus.uploading.rawValue
    }

    public func uploadQueued() -> Bool {
        uploadStatus == UploadStatus.queued.rawValue
    }

    public func uploadWaitingForWifi() -> Bool {
        uploadStatus == UploadStatus.waitingForWifi.rawValue
    }

    // MARK: - GRDB

    public static let databaseTableName = "SJUserEpisode"

    enum CodingKeys: String, CodingKey {
        case id
        case addedDate
        case lastDownloadAttemptDate
        case downloadErrorDetails
        case downloadTaskId
        case downloadUrl
        case episodeStatus
        case fileType
        case playedUpTo
        case duration
        case durationModified
        case playingStatus
        case autoDownloadStatus
        case publishedDate
        case sizeInBytes
        case playingStatusModified
        case playedUpToModified
        case title
        case titleModified
        case uuid
        case playbackErrorDetails
        case cachedFrameCount
        case uploadStatus
        case uploadTaskId
        case imageUrl
        case imageModified
        case imageColor
        case imageColorModified
        case hasCustomImage
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
        lastDownloadAttemptDate = try container.decodeIfPresent(Date.self, forKey: .lastDownloadAttemptDate)
        downloadErrorDetails = try container.decodeIfPresent(String.self, forKey: .downloadErrorDetails)
        downloadTaskId = try container.decodeIfPresent(String.self, forKey: .downloadTaskId)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        episodeStatus = try container.decodeIfPresent(Int32.self, forKey: .episodeStatus) ?? 0
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
        playedUpTo = try container.decodeIfPresent(Double.self, forKey: .playedUpTo) ?? 0
        duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 0
        durationModified = try container.decodeIfPresent(Int64.self, forKey: .durationModified) ?? 0
        playingStatus = try container.decodeIfPresent(Int32.self, forKey: .playingStatus) ?? 1
        autoDownloadStatus = try container.decodeIfPresent(Int32.self, forKey: .autoDownloadStatus) ?? 0
        publishedDate = try container.decodeIfPresent(Date.self, forKey: .publishedDate)
        sizeInBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeInBytes) ?? 0
        playingStatusModified = try container.decodeIfPresent(Int64.self, forKey: .playingStatusModified) ?? 0
        playedUpToModified = try container.decodeIfPresent(Int64.self, forKey: .playedUpToModified) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title)
        titleModified = try container.decodeIfPresent(Int64.self, forKey: .titleModified) ?? 0
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        playbackErrorDetails = try container.decodeIfPresent(String.self, forKey: .playbackErrorDetails)
        cachedFrameCount = try container.decodeIfPresent(Int64.self, forKey: .cachedFrameCount) ?? 0
        uploadStatus = try container.decodeIfPresent(Int32.self, forKey: .uploadStatus) ?? 0
        uploadTaskId = try container.decodeIfPresent(String.self, forKey: .uploadTaskId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imageModified = try container.decodeIfPresent(Int64.self, forKey: .imageModified) ?? 0
        imageColor = try container.decodeIfPresent(Int32.self, forKey: .imageColor) ?? 0
        imageColorModified = try container.decodeIfPresent(Int64.self, forKey: .imageColorModified) ?? 0
        hasCustomImage = try container.decodeIfPresent(Bool.self, forKey: .hasCustomImage) ?? false
    }

    public func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["addedDate"] = addedDate?.timeIntervalSince1970
        container["lastDownloadAttemptDate"] = (lastDownloadAttemptDate ?? Date(timeIntervalSince1970: 0)).timeIntervalSince1970
        container["downloadErrorDetails"] = downloadErrorDetails
        container["downloadTaskId"] = downloadTaskId
        container["downloadUrl"] = downloadUrl
        container["episodeStatus"] = episodeStatus
        container["fileType"] = fileType
        container["playedUpTo"] = playedUpTo
        container["duration"] = duration
        container["durationModified"] = durationModified
        container["playingStatus"] = playingStatus
        container["autoDownloadStatus"] = autoDownloadStatus
        container["publishedDate"] = publishedDate?.timeIntervalSince1970
        container["sizeInBytes"] = sizeInBytes
        container["playingStatusModified"] = playingStatusModified
        container["playedUpToModified"] = playedUpToModified
        container["title"] = title
        container["titleModified"] = titleModified
        container["uuid"] = uuid
        container["playbackErrorDetails"] = playbackErrorDetails
        container["cachedFrameCount"] = cachedFrameCount
        container["uploadStatus"] = uploadStatus
        container["uploadTaskId"] = uploadTaskId
        container["imageUrl"] = imageUrl
        container["imageModified"] = imageModified
        container["imageColor"] = imageColor
        container["imageColorModified"] = imageColorModified
        container["hasCustomImage"] = hasCustomImage
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let addedDate = Column(CodingKeys.addedDate)
        public static let lastDownloadAttemptDate = Column(CodingKeys.lastDownloadAttemptDate)
        public static let downloadErrorDetails = Column(CodingKeys.downloadErrorDetails)
        public static let downloadTaskId = Column(CodingKeys.downloadTaskId)
        public static let downloadUrl = Column(CodingKeys.downloadUrl)
        public static let episodeStatus = Column(CodingKeys.episodeStatus)
        public static let fileType = Column(CodingKeys.fileType)
        public static let playedUpTo = Column(CodingKeys.playedUpTo)
        public static let duration = Column(CodingKeys.duration)
        public static let durationModified = Column(CodingKeys.durationModified)
        public static let playingStatus = Column(CodingKeys.playingStatus)
        public static let autoDownloadStatus = Column(CodingKeys.autoDownloadStatus)
        public static let publishedDate = Column(CodingKeys.publishedDate)
        public static let sizeInBytes = Column(CodingKeys.sizeInBytes)
        public static let playingStatusModified = Column(CodingKeys.playingStatusModified)
        public static let playedUpToModified = Column(CodingKeys.playedUpToModified)
        public static let title = Column(CodingKeys.title)
        public static let titleModified = Column(CodingKeys.titleModified)
        public static let uuid = Column(CodingKeys.uuid)
        public static let playbackErrorDetails = Column(CodingKeys.playbackErrorDetails)
        public static let cachedFrameCount = Column(CodingKeys.cachedFrameCount)
        public static let uploadStatus = Column(CodingKeys.uploadStatus)
        public static let uploadTaskId = Column(CodingKeys.uploadTaskId)
        public static let imageUrl = Column(CodingKeys.imageUrl)
        public static let imageModified = Column(CodingKeys.imageModified)
        public static let imageColor = Column(CodingKeys.imageColor)
        public static let imageColorModified = Column(CodingKeys.imageColorModified)
        public static let hasCustomImage = Column(CodingKeys.hasCustomImage)
    }
}

extension UserEpisode: FetchableRecord, PersistableRecord, TableRecord, Decodable {}
