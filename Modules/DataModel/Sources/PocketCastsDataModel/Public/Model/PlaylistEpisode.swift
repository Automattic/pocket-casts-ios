import Foundation
import GRDB
import GRDBMacros

@GRDBRecord
public class PlaylistEpisode: Equatable, Hashable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "SJPlaylistEpisode"

    public var id: Int64? = 0
    public var episodePosition = 0 as Int32
    public var episodeUuid = ""
    public var playlist_id = 0 as Int64
    public var playlist_uuid: String?
    public var timeModified = 0 as Int64
    public var wasDeleted = false
    public var title: String?
    public var podcastUuid: String?

    public init() {}

    /// Updates the record's id after it has been inserted in the database.
    public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public func taggableId() -> Int {
        Int(truncatingIfNeeded: id ?? 0)
    }

    public static func == (lhs: PlaylistEpisode, rhs: PlaylistEpisode) -> Bool {
        lhs.episodeUuid == rhs.episodeUuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(episodeUuid)
    }
}

// MARK: - Associations

extension PlaylistEpisode {
    /// Foreign key to the playlist this playlist episode belongs to
    public static let playlistForeignKey = ForeignKey(["playlist_id"])

    /// Association to the playlist this episode entry belongs to
    public static let playlist = belongsTo(EpisodeFilter.self, using: playlistForeignKey)
}
