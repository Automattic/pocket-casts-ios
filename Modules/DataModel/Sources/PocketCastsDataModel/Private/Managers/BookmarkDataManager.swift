import FMDB
import PocketCastsUtils

public struct BookmarkDataManager {
    static let tableName = "Bookmark"
    private let dbQueue: FMDatabaseQueue

    init(dbQueue: FMDatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// A bookmark that represents a time range within an episode
    public struct Bookmark {
        public let uuid: String
        public let createdDate: Date
        public let timeRange: TimeRange
        public let transcription: String?

        public lazy var episode: BaseEpisode? = {
            DataManager.sharedManager.findEpisode(uuid: episodeUuid)
        }()

        public lazy var podcast: Podcast? = {
            guard let podcastUuid else {
                return nil
            }
            return DataManager.sharedManager.findPodcast(uuid: podcastUuid)
        }()

        // Internally used
        private let episodeUuid: String
        private let podcastUuid: String?

        init?(from resultSet: FMResultSet) {
            guard
                let uuid = resultSet.string(for: .uuid),
                let createdDate = resultSet.date(for: .createdDate),
                let episode = resultSet.string(for: .episode),
                let timeRange = TimeRange(from: resultSet)
            else {
                return nil
            }

            self.uuid = uuid
            self.createdDate = createdDate
            self.timeRange = timeRange
            self.episodeUuid = episode
            self.podcastUuid = resultSet.string(for: .podcast)
            self.transcription = resultSet.string(for: .transcription)
        }

        public struct TimeRange {
            public let start: TimeInterval
            public let end: TimeInterval

            init?(from resultSet: FMResultSet) {
                guard
                    let timeStartObj = resultSet.object(for: .timestampStart) as? Double,
                    let timeEndObj = resultSet.object(for: .timestampEnd) as? Double
                else {
                    return nil
                }

                start = timeStartObj
                end = timeEndObj
            }
        }
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
private extension FMResultSet {
    func object(for column: BookmarkDataManager.Column) -> Any? {
        object(forColumn: column.rawValue)
    }

    func string(for column: BookmarkDataManager.Column) -> String? {
        string(forColumn: column.rawValue)
    }

    func date(for column: BookmarkDataManager.Column) -> Date? {
        date(forColumn: column.rawValue)
    }
}

// MARK: - Private

private extension BookmarkDataManager {
    /// Looks for any existing bookmarks in an episode that have the same start/end timestampss
    func existingBookmark(forEpisode episodeUuid: String, start: TimeInterval, end: TimeInterval) -> Bookmark? {
        selectBookmarks(where: [.episode, .timestampStart, .timestampEnd],
                        values: [episodeUuid, start, end],
                        limit: 1).first
    }

    func selectBookmarks(where whereColumns: [Column], values: [Any], limit: Int = 0) -> [Bookmark] {
        let limitQuery = limit != 0 ? "LIMIT \(limit)" : ""

        let selectColumns = Column.allCases.map { $0.rawValue }
        let whereString = whereColumns.map { "\($0.rawValue) = ?" }.joined(separator: " AND ")

        var results: [Bookmark] = []

        dbQueue.inDatabase { db in
            do {
                let query = """
                    SELECT \(selectColumns.columnString)
                    FROM \(Self.tableName)
                    WHERE \(whereString)
                    ORDER BY \(Column.createdDate) DESC
                    \(limitQuery)
                """

                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    if let bookmark = Bookmark(from: resultSet) {
                        results.append(bookmark)
                    }
                }
            } catch {
                FileLog.shared.addMessage("BookmarkManager.selectBookmarks where (\(whereString) failed: \(error)")
            }
        }

        return results
    }
}
