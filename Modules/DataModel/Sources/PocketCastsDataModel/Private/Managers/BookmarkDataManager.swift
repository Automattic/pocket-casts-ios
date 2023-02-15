import FMDB
import PocketCastsUtils

public struct BookmarkDataManager {
    static let tableName = "Bookmark"
    private let dbQueue: FMDatabaseQueue

    init(dbQueue: FMDatabaseQueue) {
        self.dbQueue = dbQueue
    }
// MARK: - DB Column Constants

private extension String {
    static let uuid = "uuid"
    static let createdDate = "date_added"
    static let timestampStart = "timestamp_start"
    static let timestampEnd = "timestamp_end"
    static let episode = "episode_uuid"
    static let podcast = "podcast_uuid"
    static let transcription = "transcription"
}
}
