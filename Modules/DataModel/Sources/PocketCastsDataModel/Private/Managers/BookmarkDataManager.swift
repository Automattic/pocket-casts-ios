import FMDB
import PocketCastsUtils

public struct BookmarkDataManager {
    static let tableName = "Bookmark"
    private let dbQueue: FMDatabaseQueue

    init(dbQueue: FMDatabaseQueue) {
        self.dbQueue = dbQueue
    }

    enum Column: String, CaseIterable, CustomStringConvertible {
        case uuid
        case createdDate = "date_added"
        case episode = "episode_uuid"
        case podcast = "podcast_uuid"
        case timestampStart = "timestamp_start"
        case timestampEnd = "timestamp_end"
        case transcription

        var description: String { rawValue }
    }
}
// MARK: - DB Column Constants

}
}
