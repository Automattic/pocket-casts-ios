import Foundation
import GRDB
import GRDBMacros

/// GRDB Record type representing the PlaylistEpisodeHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
@GRDBRecord
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
}
