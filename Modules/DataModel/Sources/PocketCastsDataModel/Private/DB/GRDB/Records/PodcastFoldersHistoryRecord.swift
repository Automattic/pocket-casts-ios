import Foundation
import GRDB
import GRDBMacros

/// GRDB Record type representing the PodcastFoldersHistory table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
@GRDBRecord
struct PodcastFoldersHistoryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "PodcastFoldersHistory"

    var podcastUuid: String
    var folderUuid: String
    var date: Double
}
