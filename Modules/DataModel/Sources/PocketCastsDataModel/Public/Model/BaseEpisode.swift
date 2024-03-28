import Foundation

@objc public protocol BaseEpisode: AnyObject {
    // MARK: - Properties

    var uuid: String { get set }
    var addedDate: Date? { get set }
    var publishedDate: Date? { get set }
    var cachedFrameCount: Int64 { get set }
    var autoDownloadStatus: Int32 { get set }
    var downloadUrl: String? { get set }
    var fileType: String? { get set }
    var contentType: String? { get set }
    var title: String? { get set }
    var playbackErrorDetails: String? { get set }
    var downloadErrorDetails: String? { get set }
    var sizeInBytes: Int64 { get set }
    var lastDownloadAttemptDate: Date? { get set }
    var downloadTaskId: String? { get set }
    var playingStatusModified: Int64 { get set }
    var playedUpToModified: Int64 { get set }

    var archived: Bool { get set }
    var keepEpisode: Bool { get set }

    var episodeStatus: Int32 { get set }
    var playingStatus: Int32 { get set }

    var playedUpTo: Double { get set }
    var duration: Double { get set }

    var deselectedChapters: String? { get set }
    var deselectedChaptersModified: Int64 { get set }

    func displayableTitle() -> String
    func parentIdentifier() -> String

    // MARK: - Download

    func downloaded(pathFinder: FilePathProtocol) -> Bool
    func bufferedForStreaming() -> Bool
    func downloadFailed() -> Bool
    func downloading() -> Bool
    func queued() -> Bool
    func waitingForWifi() -> Bool
    func exemptFromAutoDownload() -> Bool
    func pathToDownloadedFile(pathFinder: FilePathProtocol) -> String
    func pathToTempFile(pathFinder: FilePathProtocol) -> String

    // MARK: - Playback

    func inProgress() -> Bool
    func played() -> Bool
    func unplayed() -> Bool
    func playbackError() -> Bool

    // MARK: - Meta Data

    func videoPodcast() -> Bool
    func mayContainChapters() -> Bool

    var hasBookmarks: Bool { get }

    // This property is true if the only filled property is the episode's UUID. If true, this object should only be used as a thin wrapper over the UUID.
    var hasOnlyUuid: Bool { get set }

    /// Whether this is a regular episode, or an user episode (File)
    var isUserEpisode: Bool { get }
}
