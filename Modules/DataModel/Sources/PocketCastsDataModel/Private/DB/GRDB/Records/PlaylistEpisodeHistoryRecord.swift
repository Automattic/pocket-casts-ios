import Foundation
import GRDB

/// GRDB Record type representing the PlaylistEpisodeHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PlaylistEpisodeHistoryRecord: Codable, Identifiable {
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

    /// Initializes a default PlaylistEpisodeHistoryRecord with reasonable defaults
    init() {
        self.id = nil
        self.episodePosition = 0
        self.episodeUuid = ""
        self.playlist_id = 0
        self.upcoming = false
        self.timeModified = 0
        self.wasDeleted = false
        self.title = nil
        self.podcastUuid = nil
        self.date = 0
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension PlaylistEpisodeHistoryRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "PlaylistEpisodeHistory"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension PlaylistEpisodeHistoryRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let episodePosition = Column(CodingKeys.episodePosition)
        static let episodeUuid = Column(CodingKeys.episodeUuid)
        static let playlist_id = Column(CodingKeys.playlist_id)
        static let upcoming = Column(CodingKeys.upcoming)
        static let timeModified = Column(CodingKeys.timeModified)
        static let wasDeleted = Column(CodingKeys.wasDeleted)
        static let title = Column(CodingKeys.title)
        static let podcastUuid = Column(CodingKeys.podcastUuid)
        static let date = Column(CodingKeys.date)
    }
}
