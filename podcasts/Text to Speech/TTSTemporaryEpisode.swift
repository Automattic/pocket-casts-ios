import Foundation
import PocketCastsDataModel
import UIKit

final class TTSTemporaryEpisode: NSObject, BaseEpisode {
    var uuid: String
    var addedDate: Date?
    var publishedDate: Date?
    var cachedFrameCount: Int64 = 0
    var autoDownloadStatus: Int32 = 0
    var downloadUrl: String?
    var fileType: String?
    var contentType: String?
    var title: String?
    var playbackErrorDetails: String?
    var downloadErrorDetails: String?
    var sizeInBytes: Int64 = 0
    var lastDownloadAttemptDate: Date?
    var downloadTaskId: String?
    var playingStatusModified: Int64 = 0
    var playedUpToModified: Int64 = 0

    var archived: Bool = false
    var keepEpisode: Bool = false
    var wasDeleted: Bool = false

    var episodeStatus: Int32 = DownloadStatus.downloaded.rawValue
    var playingStatus: Int32 = PlayingStatus.notPlayed.rawValue

    var playedUpTo: Double = 0
    var duration: Double

    var artwork: UIImage?

    var deselectedChapters: String?
    var deselectedChaptersModified: Int64 = 0

    var hasOnlyUuid: Bool = false

    var hasBookmarks: Bool { false }

    var isUserEpisode: Bool { true }

    private let fileURL: URL

    init(uuid: String, title: String, fileURL: URL, duration: Double, fileType: String) {
        self.uuid = uuid
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.fileType = fileType
        super.init()
    }

    func displayableTitle() -> String {
        title ?? "Text to Speech"
    }

    func parentIdentifier() -> String {
        DataConstants.userEpisodeFakePodcastId
    }

    func downloaded(pathFinder: FilePathProtocol) -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func bufferedForStreaming() -> Bool { false }
    func downloadFailed() -> Bool { false }
    func downloading() -> Bool { false }
    func queued() -> Bool { false }
    func waitingForWifi() -> Bool { false }
    func exemptFromAutoDownload() -> Bool { false }

    func pathToDownloadedFile(pathFinder: FilePathProtocol) -> String {
        fileURL.path
    }

    func pathToTempFile(pathFinder: FilePathProtocol) -> String {
        fileURL.path
    }

    func inProgress() -> Bool { false }
    func played() -> Bool { false }
    func unplayed() -> Bool { true }
    func playbackError() -> Bool { false }

    func videoPodcast() -> Bool { false }
    func mayContainChapters() -> Bool { false }
}
