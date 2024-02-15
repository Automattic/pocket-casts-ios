import Foundation

public enum UploadedSort: Int, CaseIterable {
    case newestToOldest = 0, oldestToNewest = 1, titleAtoZ = 2
}

public enum AutoDownloadStatus: Int32 {
    case notSpecified = 0, userDeletedFile = 1, userCancelledDownload = 2, autoDownloaded = 3, playerDownloadedForStreaming = 4
}

public enum DownloadStatus: Int32 {
    case notDownloaded = 1, queued = 2, downloading = 3, downloadFailed = 4, downloaded = 5, waitingForWifi = 6, downloadedForStreaming = 7
}

public enum AutoDownloadSetting: Int32 {
    case off = 0, latest = 1, all = 2
}

public enum PlayingStatus: Int32 {
    case notPlayed = 1, inProgress = 2, completed = 3, old = 4
}

public enum UploadStatus: Int32 {
    case notUploaded = 1, queued = 2, uploading = 3, uploadFailed = 4, uploaded = 5, waitingForWifi = 6, missing = 7, deleteFromCloudPending = 8, deleteFromCloudAndLocalPending = 9
}

public enum PodcastGrouping: Int32, CaseIterable, Codable {
    case none = 0, downloaded = 1, unplayed = 2, season = 3, starred = 4
}

public enum AudioVideoFilter: Int32 {
    case all = 0, audioOnly = 1, videoOnly = 2
}

public enum AutoAddToUpNextSetting: Int32 {
    case off = 0, addLast = 1, addFirst = 2
}

public enum SyncStatus: Int32 {
    case notSynced = 0, synced = 1, notSyncedRemove = 2
}

public enum PlaylistSort: Int32 {
    case newestToOldest = 0, oldestToNewest = 1, shortestToLongest = 2, longestToShortest = 3
}

public struct EpisodeBasicData {
    public init() {}

    public var uuid: String?
    public var duration: Int?
    public var playingStatus: Int?
    public var playedUpTo: Int?
    public var isArchived: Bool?
    public var starred: Bool?
}

public enum PodcastEpisodeSortOrder: Int32, Codable, CaseIterable {
    case newestToOldest = 1, oldestToNewest, shortestToLongest, longestToShortest
}

public enum UpNextPosition: Int32, Codable {
    case bottom = 0
    case top = 1
}
