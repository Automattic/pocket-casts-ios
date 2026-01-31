import Foundation
import GRDB
import SwiftUI

/// A bookmark that represents a position in time within an episode
public struct Bookmark: Hashable {
    public let uuid: String
    public var title: String
    public let time: TimeInterval

    public let created: Date

    public let episodeUuid: String
    public let podcastUuid: String?

    // Transient - not stored in database
    public var episode: BaseEpisode? = nil
    public var podcast: Podcast? = nil

    // For syncing
    public var titleModified: Date? = nil
    public var deletedModified: Date? = nil
    public var deleted: Bool = false
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

// MARK: - GRDB Codable Support

extension Bookmark: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "Bookmark"

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case time
        case created = "date_added"
        case episodeUuid = "episode_uuid"
        case podcastUuid = "podcast_uuid"
        case titleModified = "title_modified_date"
        case deletedModified = "deleted_modified_date"
        case deleted
        case syncStatus = "sync_status"
    }

    /// Column definitions for type-safe query building
    public enum Columns {
        public static let uuid = Column(CodingKeys.uuid)
        public static let title = Column(CodingKeys.title)
        public static let time = Column(CodingKeys.time)
        public static let created = Column(CodingKeys.created)
        public static let episodeUuid = Column(CodingKeys.episodeUuid)
        public static let podcastUuid = Column(CodingKeys.podcastUuid)
        public static let titleModified = Column(CodingKeys.titleModified)
        public static let deletedModified = Column(CodingKeys.deletedModified)
        public static let deleted = Column(CodingKeys.deleted)
        public static let syncStatus = Column(CodingKeys.syncStatus)
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
