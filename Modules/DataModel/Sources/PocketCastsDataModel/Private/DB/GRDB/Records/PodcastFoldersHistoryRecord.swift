import Foundation
import GRDB

/// GRDB Record type representing the PodcastFoldersHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PodcastFoldersHistoryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "PodcastFoldersHistory"

    var podcastUuid: String
    var folderUuid: String
    var date: Double

    /// Column definitions for type-safe query building
    enum Columns {
        static let podcastUuid = Column("podcastUuid")
        static let folderUuid = Column("folderUuid")
        static let date = Column("date")
    }
}
