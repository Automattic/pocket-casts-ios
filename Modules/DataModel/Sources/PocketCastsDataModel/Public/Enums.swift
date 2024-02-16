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
