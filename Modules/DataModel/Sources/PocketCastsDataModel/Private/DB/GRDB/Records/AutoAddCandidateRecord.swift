import Foundation
import GRDB

/// GRDB Record type representing the AutoAddCandidates table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct AutoAddCandidateRecord: Codable, Identifiable {
    var id: Int64?
    var episode_uuid: String
    var podcast_uuid: String

    /// Initializes a default AutoAddCandidateRecord with reasonable defaults
    init() {
        self.id = nil
        self.episode_uuid = ""
        self.podcast_uuid = ""
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension AutoAddCandidateRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "AutoAddCandidates"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension AutoAddCandidateRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let episode_uuid = Column(CodingKeys.episode_uuid)
        static let podcast_uuid = Column(CodingKeys.podcast_uuid)
    }
}
