import Foundation
import GRDB

/// GRDB Record type representing the AutoAddCandidates table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct AutoAddCandidateRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "AutoAddCandidates"

    var id: Int64?
    var episode_uuid: String
    var podcast_uuid: String

    /// Default initializer for creating new records
    init() {
        self.id = nil
        self.episode_uuid = ""
        self.podcast_uuid = ""
    }

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column("id")
        static let episode_uuid = Column("episode_uuid")
        static let podcast_uuid = Column("podcast_uuid")
    }
}
