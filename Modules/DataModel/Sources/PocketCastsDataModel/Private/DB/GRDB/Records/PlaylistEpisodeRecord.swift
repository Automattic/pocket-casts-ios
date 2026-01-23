import Foundation
import GRDB

/// GRDB Record type representing the SJPlaylistEpisode table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PlaylistEpisodeRecord: Codable, Identifiable {
    var id: Int64?
    var episodePosition: Int32
    var episodeUuid: String
    var playlist_id: Int64
    var playlist_uuid: String?
    var timeModified: Int64
    var wasDeleted: Bool
    var title: String?
    var podcastUuid: String?

    /// Initializes a default PlaylistEpisodeRecord with reasonable defaults
    init() {
        self.id = nil
        self.episodePosition = 0
        self.episodeUuid = ""
        self.playlist_id = 0
        self.playlist_uuid = nil
        self.timeModified = 0
        self.wasDeleted = false
        self.title = nil
        self.podcastUuid = nil
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension PlaylistEpisodeRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "SJPlaylistEpisode"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension PlaylistEpisodeRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let episodePosition = Column(CodingKeys.episodePosition)
        static let episodeUuid = Column(CodingKeys.episodeUuid)
        static let playlist_id = Column(CodingKeys.playlist_id)
        static let playlist_uuid = Column(CodingKeys.playlist_uuid)
        static let timeModified = Column(CodingKeys.timeModified)
        static let wasDeleted = Column(CodingKeys.wasDeleted)
        static let title = Column(CodingKeys.title)
        static let podcastUuid = Column(CodingKeys.podcastUuid)
    }
}

// MARK: - Associations

extension PlaylistEpisodeRecord {
    /// Foreign key to the playlist this playlist episode belongs to
    static let playlistForeignKey = ForeignKey(["playlist_id"])

    /// Association to the playlist this episode entry belongs to
    static let playlist = belongsTo(PlaylistRecord.self, using: playlistForeignKey)
}
