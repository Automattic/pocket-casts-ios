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

public enum AutoArchiveAfterPlayed: Int32, Codable {
    case never = 0
    case afterPlaying = 1
    case after24Hours = 2
    case after2Days = 3
    case after1Week = 4
}

public enum AutoArchiveAfterInactive: Int32, Codable {
    case never = 0
    case after24Hours = 1
    case after2Days = 2
    case after1Week = 3
    case after2Weeks = 4
    case after30Days = 5
    case after3Months = 6
}

public enum AutoArchiveAfterTime: TimeInterval {
    case never = -1
    case afterPlaying = 0
    case after1Day = 86400
    case after2Days = 172_800
    case after1Week = 604_800
    case after2Weeks = 1_209_600
    case after30Days = 2_592_000
    case after90Days = 7_776_000
}

extension AutoArchiveAfterPlayed {
    public init?(time: AutoArchiveAfterTime) {
        switch time {
        case .never:
            self = .never
        case .afterPlaying:
            self = .afterPlaying
        case .after1Day:
            self = .after24Hours
        case .after2Days:
            self = .after2Days
        case .after1Week:
            self = .after1Week
        case .after2Weeks, .after30Days, .after90Days:
            return nil
        }
    }

    public var time: AutoArchiveAfterTime {
        switch self {
            case .never:
                return .never
            case .afterPlaying:
                return .afterPlaying
            case .after24Hours:
                return .after1Day
            case .after2Days:
                return .after2Days
            case .after1Week:
                return .after1Week
        }
    }
}

extension AutoArchiveAfterInactive {
    public init?(time: AutoArchiveAfterTime) {
        switch time {
        case .never:
            self = .never
        case .after1Day:
            self = .after24Hours
        case .after2Days:
            self = .after2Days
        case .after1Week:
            self = .after1Week
        case .after2Weeks:
            self = .after2Weeks
        case .after30Days:
            self = .after30Days
        case .after90Days:
            self = .after3Months
        case .afterPlaying:
            return nil
        }
    }

    public var time: AutoArchiveAfterTime {
        switch self {
            case .never:
                return .never
            case .after24Hours:
                return .after1Day
            case .after2Days:
                return .after2Days
            case .after1Week:
                return .after1Week
            case .after2Weeks:
                return .after2Weeks
            case .after30Days:
                return .after30Days
            case .after3Months:
                return .after90Days
        }
    }
}
