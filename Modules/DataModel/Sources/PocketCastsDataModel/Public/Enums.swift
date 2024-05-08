import Foundation

public enum UploadedSort: Int32, CaseIterable, Codable {
    case newestToOldest = 0, oldestToNewest = 1, titleAtoZ = 2, titleZtoA = 3, shortestToLongest = 4, longestToShortest = 5

    public enum Old: Int {
        case newestToOldest = 0, oldestToNewest = 1, titleAtoZ = 2
    }

    public init(old: Old) {
        switch old {
        case .newestToOldest:
            self = .newestToOldest
        case .oldestToNewest:
            self = .oldestToNewest
        case .titleAtoZ:
            self = .titleAtoZ
        }
    }
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
    public var deselectedChapters: String?
}

public enum LibrarySort: Int32, CaseIterable, Codable {
    case dateAddedNewestToOldest = 0, titleAtoZ = 1, episodeDateNewestToOldest = 2, custom = 3
}

public enum LibraryType: Int32, Codable {
    case threeByThree = 0, fourByFour = 1, list = 2
}

public enum BadgeType: Int32, Codable {
    case off = 0, latestEpisode, allUnplayed
}

public enum PodcastEpisodeSortOrder: Int32, Codable, CaseIterable {
    case titleAtoZ
    case titleZtoA
    case oldestToNewest
    case newestToOldest
    case shortestToLongest
    case longestToShortest

    public enum Old: Int32 {
        case newestToOldest = 1, oldestToNewest, shortestToLongest, longestToShortest
    }

    public init(old: Old) {
        switch old {
        case .newestToOldest:
            self = .newestToOldest
        case .oldestToNewest:
            self = .oldestToNewest
        case .shortestToLongest:
            self = .shortestToLongest
        case .longestToShortest:
            self = .longestToShortest
        }
    }

    public var old: Old {
        switch self {
        case .newestToOldest:
            .newestToOldest
        case .oldestToNewest:
            .oldestToNewest
        case .shortestToLongest:
            .shortestToLongest
        case .longestToShortest:
            .longestToShortest
        case .titleAtoZ:
            .newestToOldest
        case .titleZtoA:
            .newestToOldest
        }
    }
}

public enum BookmarksSort: Int32, Codable {
    case newestToOldest = 0
    case oldestToNewest = 1
    case timestamp = 2
    case episode = 3
    case podcastAndEspisode = 4
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

public enum TrimSilence: Int32, Codable {
    case off = 0
    case mild = 1
    case medium = 2
    case madMax = 3
}

/// A value representing a type with a `known` and `unknown` value.
/// The `known` value is of type`Present` and `unknown` of type `Absent`
public enum Option<Present, Absent> {
    case known(Present)
    case unknown(Absent)
}

/// Conformance to RawRepresentable by first checking for the Present `known` type and then falling back to setting the raw value as `unknown`
extension Option: RawRepresentable where Present: RawRepresentable<Absent> {
    public init?(rawValue: Absent) {
        if let known = Present(rawValue: rawValue) {
            self = .known(known)
        } else {
            self = .unknown(rawValue)
        }
    }

    public var rawValue: Absent {
        switch self {
        case .known(let present):
            return present.rawValue
        case .unknown(let absent):
            return absent
        }
    }
}

public typealias ActionOption = Option<PlayerAction, String>

extension ActionOption: Codable, Equatable {}

public enum PlayerAction: String, Codable, Equatable {
    case effects = "effects"
    case sleepTimer = "sleep"
    case routePicker = "airplay"
    case starEpisode = "star"
    case shareEpisode = "share"
    case goToPodcast = "podcast"
    case chromecast = "case"
    case markPlayed = "played"
    case archive = "archive"
    case addBookmark = "bookmark"
}

extension Array: RawRepresentable where Element: RawRepresentable<String> {
    public typealias RawValue = String

    public init?(rawValue: String) {
        self = rawValue.split(separator: ",").compactMap { item in
            Element(rawValue: String(item))
        }
    }

    public var rawValue: String {
        map(\.rawValue).joined(separator: ",")
    }
}

public enum UpNextPosition: Int32, Codable {
    case bottom = 0
    case top = 1
}
