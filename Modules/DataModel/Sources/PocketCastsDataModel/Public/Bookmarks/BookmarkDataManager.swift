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
    public func add(uuid: String? = nil, episodeUuid: String, podcastUuid: String?, title: String, time: TimeInterval, dateCreated: Date = Date()) -> String? {
        // Prevent adding more than 1 bookmark at the same place
        guard existingBookmark(forEpisode: episodeUuid, time: time) == nil else {
            return nil
        }

        var bookmarkUuid: String? = nil

        dbQueue.inDatabase { db in
            do {
                let uuid = uuid ?? UUID().uuidString.lowercased()
                let created = dateCreated.timeIntervalSince1970

                let columns: [Column] = [
                    .uuid, .title, .time,
                    .createdDate, .modifiedDate,
                    .episode, .podcast
                ]

                let values: [Any?] = [uuid, title, time, created, created, episodeUuid, podcastUuid]

                try db.insert(into: Self.tableName, columns: columns.map { $0.rawValue }, values: values)

                bookmarkUuid = uuid
            } catch {
                FileLog.shared.addMessage("BookmarkManager.add failed: \(error)")
            }
        }

        return bookmarkUuid
    }

    // MARK: - Updating
    @discardableResult
    public func update(bookmark: Bookmark, title: String, time: TimeInterval? = nil, created: Date? = nil, modified: Date? = Date()) async -> Bool {
        let updateColumns = [
            "\(Column.title) = ?",
            time.map { _ in "\(Column.time) = ?" },
            created.map { _ in "\(Column.createdDate) = ?" },
            modified.map { _ in "\(Column.modifiedDate) = ?" },
        ].compactMap { $0 }

        let values: [Any?] = [
            title,
            time,
            created,
            modified,
            bookmark.uuid
        ]

        let query = """
                UPDATE \(Self.tableName)
                SET \(updateColumns.columnString)
                WHERE \(Column.uuid) = ?
                LIMIT 1
                """

        let result = await dbQueue.executeUpdate(query, values: values.compactMap { $0 })

        switch result {
        case .success:
            return true
        case .failure(let failure):
            FileLog.shared.addMessage("BookmarkManager.update failed: \(failure)")
            return false
        }
    }

    // MARK: - Retrieving

    /// Retrieves a single Bookmark for the given UUID
    public func bookmark(for uuid: String) -> Bookmark? {
        selectBookmarks(where: [.uuid], values: [uuid], limit: 1).first
    }

    /// Retrieves all the Bookmarks for an episode
    public func bookmarks(forEpisode episodeUuid: String, sorted: SortOption = .newestToOldest) -> [Bookmark] {
        selectBookmarks(where: [.episode], values: [episodeUuid], sorted: sorted)
    }

    /// Retrieves all the bookmarks for a podcast, and optionally a specific episode of that podcast
    public func bookmarks(forPodcast podcastUuid: String, episodeUuid: String? = nil, sorted: SortOption = .newestToOldest) -> [Bookmark] {
        var values = [podcastUuid]
        var whereColumns = [Column.podcast]

        if let episodeUuid {
            whereColumns.append(.episode)
            values.append(episodeUuid)
        }

        return selectBookmarks(where: whereColumns, values: values, sorted: sorted)
    }

    /// Returns all the bookmarks in the database and optionally can also return deleted items
    public func allBookmarks(includeDeleted: Bool = false, sorted: SortOption = .newestToOldest) -> [Bookmark] {
        selectBookmarks(where: [.deleted], values: [includeDeleted], sorted: sorted)
    }

    /// Returns the number of bookmarks for the given episode and can optionally include deleted items in the count
    public func bookmarkCount(forEpisode episodeUuid: String, includeDeleted: Bool = false) -> Int {
        let deletedWhere: String? = includeDeleted ? nil : "\(Column.deleted) = 0"

        let whereString = [deletedWhere, "\(Column.episode) = ?"]
            .compactMap { $0 }.joined(separator: " AND ")

        let query = "SELECT COUNT(*) FROM \(Self.tableName) WHERE \(whereString)"

        var count = 0
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: [episodeUuid])
                resultSet.next()
                count = resultSet.long(forColumnIndex: 0)
                resultSet.close()
            } catch {
                FileLog.shared.addMessage("BookmarkManager.bookmarkCount failed: \(error)")
            }
        }

        return count
    }

    // MARK: - Deleting

    /// Marks the bookmarks as deleted, but doesn't actually remove them from the database
    public func remove(bookmarks: [Bookmark]) async -> Bool {
        let uuids = bookmarks.map { "'\($0.uuid)'" }.joined(separator: ",")

        let query = """
        UPDATE \(Self.tableName)
        SET \(Column.deleted) = 1
        WHERE \(Column.uuid) IN (\(uuids))
        """

        let result = await dbQueue.executeUpdate(query)

        switch result {
        case .success:
            return true
        case .failure(let error):
            FileLog.shared.addMessage("BookmarkManager.remove failed: \(error)")
            return false
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

    // MARK: - Sortings

    public enum SortOption {
        case newestToOldest, oldestToNewest, timestamp

        var queryString: String {
            switch self {
            case .newestToOldest:
                return "ORDER BY \(Column.createdDate) DESC"
            case .oldestToNewest:
                return "ORDER BY \(Column.createdDate) ASC"
            case .timestamp:
                return "ORDER BY \(Column.time) ASC"
            }
        }
    }

    // MARK: - Columns

    enum Column: String, CaseIterable, CustomStringConvertible {
        case uuid
        case title
        case createdDate = "date_added"
        case modifiedDate = "date_modified"
        case episode = "episode_uuid"
        case podcast = "podcast_uuid"
        case time
        case deleted

        var description: String { rawValue }
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

    func selectBookmarks(where whereColumns: [Column], values: [Any], limit: Int = 0, sorted: SortOption = .newestToOldest) -> [Bookmark] {
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
                    \(sorted.queryString)
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
                \(Column.title) varchar(100) NOT NULL,
                \(Column.episode) varchar(40) NOT NULL,
                \(Column.podcast) varchar(40),
                \(Column.time) real NOT NULL,
                \(Column.createdDate) INTEGER NOT NULL,
                \(Column.modifiedDate) INTEGER NOT NULL,
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
            let title = resultSet.string(for: .title),
            let createdDate = resultSet.date(for: .createdDate),
            let modified = resultSet.date(for: .modifiedDate),
            let episode = resultSet.string(for: .episode),
            let time = resultSet.double(for: .time)
        else {
            return nil
        }

        let podcast = resultSet.string(for: .podcast)

        self.init(uuid: uuid,
                  title: title,
                  time: time,
                  created: createdDate,
                  modified: modified,
                  episodeUuid: episode,
                  podcastUuid: podcast)
    }
}

// MARK: - BookmarkDataManager.Column: FMResultSet Extension

private extension FMResultSet {
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
