import Foundation
import GRDB

/// GRDB Record type representing the PodcastFoldersHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PodcastFoldersHistoryRecord: Codable {
    var podcastUuid: String
    var folderUuid: String
    var date: Double

    /// Initializes a default PodcastFoldersHistoryRecord with reasonable defaults
    init() {
        self.podcastUuid = ""
        self.folderUuid = ""
        self.date = 0
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension PodcastFoldersHistoryRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "PodcastFoldersHistory"
}

// MARK: - Column Definitions

extension PodcastFoldersHistoryRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let podcastUuid = Column(CodingKeys.podcastUuid)
        static let folderUuid = Column(CodingKeys.folderUuid)
        static let date = Column(CodingKeys.date)
    }
}
