import Foundation
import GRDB

/// GRDB Record type representing the PlaylistEpisodeHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PlaylistEpisodeHistoryRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "PlaylistEpisodeHistory"

    var id: Int64?
    var episodePosition: Int32
    var episodeUuid: String
    var playlist_id: Int64
    var upcoming: Bool
    var timeModified: Int64
    var wasDeleted: Bool
    var title: String?
    var podcastUuid: String?
    var date: Double

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column("id")
        static let episodePosition = Column("episodePosition")
        static let episodeUuid = Column("episodeUuid")
        static let playlist_id = Column("playlist_id")
        static let upcoming = Column("upcoming")
        static let timeModified = Column("timeModified")
        static let wasDeleted = Column("wasDeleted")
        static let title = Column("title")
        static let podcastUuid = Column("podcastUuid")
        static let date = Column("date")
    }
}
