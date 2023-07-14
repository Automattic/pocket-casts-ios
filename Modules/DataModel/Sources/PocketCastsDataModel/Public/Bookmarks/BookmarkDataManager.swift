import FMDB
import PocketCastsUtils

public struct BookmarkDataManager {
    static let tableName = "Bookmark"
    private let dbQueue: FMDatabaseQueue

    init(dbQueue: FMDatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Adding

    /// Adds a new bookmark to the database
    /// - Parameters:
    ///   - episodeUuid: The UUID of the episode we're adding to
    ///   - podcastUuid: The UUID of the podcast of the episode, can be nil for user episodes
    ///   - time: The playback time for the bookmark
    ///   - transcription: A transcription of the clip if available
    @discardableResult
    public func add(episodeUuid: String, podcastUuid: String?, time: TimeInterval, dateCreated: Date = Date()) -> String? {
        // Prevent adding more than 1 bookmark at the same place
        if let existing = existingBookmark(forEpisode: episodeUuid, time: time) {
            return existing.uuid
        }

        var bookmarkUuid: String? = nil

        dbQueue.inDatabase { db in
            do {
                let uuid = UUID().uuidString.lowercased()
                let created = dateCreated.timeIntervalSince1970

                let columns = Column.insertColumns
                let values: [Any?] = [uuid, created, episodeUuid, podcastUuid, time]

                try db.insert(into: Self.tableName, columns: columns.map { $0.rawValue }, values: values)

                bookmarkUuid = uuid
            } catch {
                FileLog.shared.addMessage("BookmarkManager.add failed: \(error)")
            }
        }

        return bookmarkUuid
    }

    // MARK: - Retrieving

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

    /// Returns all the bookmarks in the database and optionally can also return deleted items
    public func allBookmarks(includeDeleted: Bool) -> [Bookmark] {
        selectBookmarks(where: [.deleted], values: [includeDeleted])
    }

    // MARK: - Deleting

    /// Marks the bookmarks as deleted, but doesn't actually remove them from the database
    public func remove(bookmarks: [Bookmark]) async -> Bool {
        await withCheckedContinuation { continuation in
            let uuids = bookmarks.map { "'\($0.uuid)'" }.joined(separator: ",")

            let query = """
            UPDATE \(Self.tableName)
            SET \(Column.deleted) = 1
            WHERE \(Column.uuid) IN (\(uuids))
            """

            dbQueue.inDatabase { db in
                do {
                    try db.executeUpdate(query, values: nil)
                    continuation.resume(returning: true)
                } catch {
                    FileLog.shared.addMessage("BookmarkManager.remove failed: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    /// Permanently removes the bookmarks from the database
    public func permanentlyDelete(bookmarks: [Bookmark]) async -> Bool {
        await withCheckedContinuation { continuation in
            let uuids = bookmarks.map { "'\($0.uuid)'" }.joined(separator: ",")

            let query = """
            DELETE FROM \(Self.tableName)
            WHERE \(Column.uuid) IN (\(uuids))
            """

            dbQueue.inDatabase { db in
                do {
                    try db.executeUpdate(query, values: nil)
                    continuation.resume(returning: true)
                } catch {
                    FileLog.shared.addMessage("BookmarkManager.remove failed: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    enum Column: String, CaseIterable, CustomStringConvertible {
        case uuid
        case createdDate = "date_added"
        case episode = "episode_uuid"
        case podcast = "podcast_uuid"
        case time
        case deleted

        var description: String { rawValue }

        /// The columns used when inserting a new row into the database
        static let insertColumns: [Column] = [
            .uuid, .createdDate, .episode, .podcast, .time
        ]
    }
}

// MARK: - Private

private extension BookmarkDataManager {
    /// Looks for any existing bookmarks in an episode that have the same start time
    func existingBookmark(forEpisode episodeUuid: String, time: TimeInterval) -> Bookmark? {
        selectBookmarks(where: [.episode, .time],
                        values: [episodeUuid, time],
                        limit: 1).first
    }

    func selectBookmarks(where whereColumns: [Column], values: [Any], limit: Int = 0) -> [Bookmark] {
        let limitQuery = limit != 0 ? "LIMIT \(limit)" : ""

        let selectColumns = Column.allCases.map { $0.rawValue }
        let whereString = whereColumns.map { "\($0.rawValue) = ?" }.joined(separator: " AND ")

        // If the deleted column isn't specified, then by default exclude deleted items
        let deleteString = whereColumns.contains(.deleted) ? "" : "AND \(Column.deleted) = 0"

        var results: [Bookmark] = []

        dbQueue.inDatabase { db in
            do {
                let query = """
                    SELECT \(selectColumns.columnString)
                    FROM \(Self.tableName)
                    WHERE \(whereString)
                    \(deleteString)
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

// MARK: - Schema Creation
extension BookmarkDataManager {
    static func createTable(in db: FMDatabase) throws {
        try db.executeUpdate("""
            CREATE TABLE IF NOT EXISTS \(Self.tableName) (
                \(Column.uuid) varchar(40) NOT NULL,
                \(Column.episode) varchar(40) NOT NULL,
                \(Column.podcast) varchar(40),
                \(Column.time) real NOT NULL,
                \(Column.createdDate) INTEGER NOT NULL,
                \(Column.deleted) int NOT NULL DEFAULT 0,
                PRIMARY KEY (\(Column.uuid))
            );
        """, values: nil)

        try db.executeUpdate("CREATE INDEX IF NOT EXISTS bookmark_uuid ON \(Self.tableName) (\(Column.uuid));", values: nil)
        try db.executeUpdate("CREATE INDEX IF NOT EXISTS bookmark_episode ON \(Self.tableName) (\(Column.episode));", values: nil)
        try db.executeUpdate("CREATE INDEX IF NOT EXISTS bookmark_podcast ON \(Self.tableName) (\(Column.podcast));", values: nil)
        try db.executeUpdate("CREATE INDEX IF NOT EXISTS bookmark_deleted ON \(Self.tableName) (\(Column.deleted));", values: nil)
    }
}

// MARK: - Bookmark from FMResultSet
private extension Bookmark {
    init?(from resultSet: FMResultSet) {
        guard
            let uuid = resultSet.string(for: .uuid),
            let createdDate = resultSet.date(for: .createdDate),
            let episode = resultSet.string(for: .episode),
            let time = resultSet.double(for: .time)
        else {
            return nil
        }

        let title: String? = nil
        let podcast = resultSet.string(for: .podcast)

        self.init(uuid: uuid,
                  createdDate: createdDate,
                  time: time,
                  title: title,
                  episodeUuid: episode,
                  podcastUuid: podcast)
    }
}

// MARK: - BookmarkDataManager.Column: FMResultSet Extension
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

    func double(for column: BookmarkDataManager.Column) -> Double? {
        double(forColumn: column.rawValue)
    }
}
