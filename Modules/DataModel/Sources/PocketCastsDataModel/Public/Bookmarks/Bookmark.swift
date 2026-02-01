import Foundation
import GRDB
import GRDBMacros
import SwiftUI

/// A bookmark that represents a position in time within an episode
@GRDBRecord(table: "Bookmark")
public struct Bookmark: Hashable {
    public let uuid: String
    public var title: String
    public let time: TimeInterval

    @GRDBColumn("date_added")
    public let created: Date

    @GRDBColumn("episode_uuid")
    public let episodeUuid: String
    @GRDBColumn("podcast_uuid")
    public let podcastUuid: String?

    // Transient - not stored in database
    @GRDBIgnore
    public var episode: BaseEpisode? = nil
    @GRDBIgnore
    public var podcast: Podcast? = nil

    // For syncing
    @GRDBColumn("title_modified_date")
    public var titleModified: Date? = nil
    @GRDBColumn("deleted_modified_date")
    public var deletedModified: Date? = nil
    public var deleted: Bool = false
    @GRDBColumn("sync_status")
    public var syncStatus: Int32 = SyncStatus.notSynced.rawValue

    // `BaseEpisode` and `Podcast` don't conform to Hashable, so instead we implement it manually to ignore those properties
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(title)
        hasher.combine(time)
        hasher.combine(created)
        hasher.combine(episodeUuid)
        hasher.combine(podcastUuid)
        hasher.combine(titleModified)
        hasher.combine(deletedModified)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - Identifiable

extension Bookmark: Identifiable {
    public var id: String { uuid }
}

// MARK: - Preview Data

extension PreviewProvider {
    public static func previewBookmark(title: String, time: TimeInterval, created: Date) -> Bookmark {
        Bookmark(uuid: UUID().uuidString,
                 title: title,
                 time: time,
                 created: created,
                 episodeUuid: "episode",
                 podcastUuid: "podcast")
    }
}
