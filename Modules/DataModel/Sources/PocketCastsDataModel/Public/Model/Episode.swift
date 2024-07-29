import Foundation
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
        if let fileType = fileType, fileType.startsWith(string: "video/") {
            return true
        }

        return false
    }

    // MARK: - Helpers

    public func mayContainChapters() -> Bool {
        guard let fileType = fileType else { return false }

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

        public struct Transcript: Decodable {
            public let url: String
            public let type: String
            public let language: String?

            public var transcriptFormat: TranscriptFormat? {
                return TranscriptFormat(rawValue: self.type)
            }
        }

        public enum TranscriptFormat: String {

            case srt = "application/srt"
            case vtt = "text/vtt"
            case textHTML = "text/html"

            public var fileExtension: String {
                switch self {
                case .srt:
                    return "srt"
                case .vtt:
                    return "vtt"
                case .textHTML:
                    return "html"
                }
            }

            // Transcript formats we support in order of priority of use
            public static let supportedFormats: [TranscriptFormat] = [.vtt, .srt, .textHTML]

            public static func bestTranscript(from available: [Transcript]) -> Transcript? {
                for format in Self.supportedFormats {
                    if let transcript = available.first(where: { $0.type == format.rawValue}) {
                        return transcript
                    }
                }
                return available.first
            }
        }
    }
}
