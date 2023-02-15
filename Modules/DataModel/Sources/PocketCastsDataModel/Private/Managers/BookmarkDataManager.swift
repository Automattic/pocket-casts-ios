import FMDB
import PocketCastsUtils

public struct BookmarkDataManager {
    static let tableName = "Bookmark"
    private let dbQueue: FMDatabaseQueue

    init(dbQueue: FMDatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Adds a new bookmark to the database
    /// - Parameters:
    ///   - episodeUuid: The UUID of the episode we're adding to
    ///   - podcastUuid: The UUID of the podcast of the episode, can be nil for user episodes
    ///   - start: The start time interval of the clip
    ///   - end: The end time interval of the clip
    ///   - transcription: A transcription of the clip if available
    public func add(episodeUuid: String, podcastUuid: String?, start: TimeInterval, end: TimeInterval, transcription: String? = nil) {
        // Prevent adding more than 1 bookmark at the same place
        if existingBookmark(forEpisode: episodeUuid, start: start, end: end) != nil {
            return
        }

        let uuid = UUID().uuidString.lowercased()
        let now = Date().timeIntervalSince1970

        let columns = Column.allCases
        let values: [Any?] = [uuid, now, episodeUuid, podcastUuid, start, end, transcription]

        dbQueue.inDatabase { db in
            do {
                try db.insert(into: Self.tableName, columns: columns.map { $0.rawValue }, values: values)
            } catch {
                FileLog.shared.addMessage("BookmarkManager.add failed: \(error)")
            }
        }
    }

    /// Retrieves a single Bookmark for the given UUID
    public func bookmark(for uuid: String) -> Bookmark? {
        selectBookmarks(where: [.uuid], values: [uuid], limit: 1).first
    }

    /// Retrieves all the Bookmarks for an episode
    public func bookmarks(forEpisode episodeUuid: String) -> [Bookmark] {
        selectBookmarks(where: [.episode], values: [episodeUuid])
    }

    /// Retrieves all the bookmarks for a podcast, and optionally a specific episode of that podcast
    public func bookmarks(forPodcast podcastUuid: String, episodeUuid: String? = nil) -> [Bookmark] {
        var values = [podcastUuid]
        var whereColumns = [Column.podcast]

        if let episodeUuid {
            whereColumns.append(.episode)
            values.append(episodeUuid)
        }

        return selectBookmarks(where: whereColumns, values: values)
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

        // Internally used to lazily load the episode/podcast
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
                    let start = resultSet.object(for: .timestampStart) as? Double,
                    let end = resultSet.object(for: .timestampEnd) as? Double
                else {
                    return nil
                }

                self.start = start
                self.end = end
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
