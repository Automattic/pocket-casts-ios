import Foundation

public class UserEpisode: NSObject, BaseEpisode {
    @objc public var id = 0 as Int64
    @objc public var addedDate: Date?
    @objc public var lastDownloadAttemptDate: Date?
    @objc public var downloadErrorDetails: String?
    @objc public var downloadTaskId: String?
    @objc public var downloadUrl: String?
    @objc public var episodeStatus = 0 as Int32
    @objc public var fileType: String?
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
    @objc public var deselectedChapters: String?
    @objc public var deselectedChaptersModified = 0 as Int64
    @objc public var image: String?
    @objc public var showNotes: String?

    // UserEpisode's are never archived or starred
    public var archived = false
    public var keepEpisode = false

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
        if let fileType = fileType, fileType.startsWith(string: "video/") {
            return true
        }

        return false
    }

    public func mayContainChapters() -> Bool {
        guard let fileType = fileType else { return false }

        return (fileType.caseInsensitiveCompare("audio/x-m4a") == .orderedSame || fileType.caseInsensitiveCompare("audio/x-m4b") == .orderedSame || fileType.caseInsensitiveCompare("audio/mp3") == .orderedSame || fileType.caseInsensitiveCompare("audio/mpeg") == .orderedSame)
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
}
