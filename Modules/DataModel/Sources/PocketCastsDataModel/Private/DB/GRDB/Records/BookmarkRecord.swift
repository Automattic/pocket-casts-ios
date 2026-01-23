import Foundation
import GRDB

/// GRDB Record type representing the Bookmark table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct BookmarkRecord: Codable {
    var uuid: String
    var title: String
    var time: Double
    var date_added: Double
    var title_modified_date: Double?
    var episode_uuid: String
    var podcast_uuid: String?
    var sync_status: Int32
    var deleted: Bool
    var deleted_modified_date: Double?

    /// Initializes a default BookmarkRecord with reasonable defaults
    init() {
        self.uuid = ""
        self.title = ""
        self.time = 0
        self.date_added = 0
        self.title_modified_date = nil
        self.episode_uuid = ""
        self.podcast_uuid = nil
        self.sync_status = 0
        self.deleted = false
        self.deleted_modified_date = nil
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension BookmarkRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "Bookmark"
}

// MARK: - Column Definitions

extension BookmarkRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let uuid = Column(CodingKeys.uuid)
        static let title = Column(CodingKeys.title)
        static let time = Column(CodingKeys.time)
        static let date_added = Column(CodingKeys.date_added)
        static let title_modified_date = Column(CodingKeys.title_modified_date)
        static let episode_uuid = Column(CodingKeys.episode_uuid)
        static let podcast_uuid = Column(CodingKeys.podcast_uuid)
        static let sync_status = Column(CodingKeys.sync_status)
        static let deleted = Column(CodingKeys.deleted)
        static let deleted_modified_date = Column(CodingKeys.deleted_modified_date)
    }
}
