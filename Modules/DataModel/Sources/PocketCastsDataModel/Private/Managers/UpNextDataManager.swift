import FMDB
import GRDB
import PocketCastsUtils

class UpNextDataManager {
    private static let upNextPlaylistId = 1

    private let columnNames = [
        "id",
        "episodePosition",
        "episodeUuid",
        "playlist_id",
        "title",
        "podcastUuid"
    ]

    private var cachedItems = [PlaylistEpisode]()
    private var allUuids = Set<String>()
    private lazy var cachedItemsQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.UpNextItemsQueue")

        return queue
    }()

    func setup(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    // MARK: - Queries

    func allUpNextPlaylistEpisodes(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [PlaylistEpisode] {
        cachedItemsQueue.sync {
            cachedItems
        }
    }

    func findPlaylistEpisode(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            for episode in cachedItems {
                if episode.episodeUuid == uuid {
                    return episode
                }
            }

            return nil
        }
    }

    func playlistEpisodeAt(index: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            cachedItems[safe: index]
        }
    }

    func positionForPlaylistEpisode(bottomOfList: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int32 {
        cachedItemsQueue.sync {
            if bottomOfList {
                if let lastItem = cachedItems.last {
                    return lastItem.episodePosition + 1
                }
            }

            return 1
        }
    }

    func playlistEpisodeCount(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        cachedItemsQueue.sync {
            cachedItems.count
        }
    }

    func isEpisodePresent(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        cachedItemsQueue.sync {
            return allUuids.contains(uuid)
        }
    }

    // MARK: - Updates

    func save(playlistEpisode: PlaylistEpisode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                // move every episode after this one down one, if there are any
                try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = episodePosition + 1 WHERE episodePosition >= ? AND episodeUuid != ? AND wasDeleted = 0", arguments: [playlistEpisode.episodePosition, playlistEpisode.episodeUuid])

                if playlistEpisode.id == 0 {
                    playlistEpisode.id = DBUtils.generateUniqueId()
                    try db.execute(sql: "INSERT INTO \(DataManager.playlistEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(playlistEpisode: playlistEpisode))!)
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET \(setStatement) WHERE id = ?", arguments: StatementArguments(self.createValuesFrom(playlistEpisode: playlistEpisode, includeIdForWhere: true))!)
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.save error: \(error)")
        }
        saveOrdering(dbQueue: dbQueue, dbPool: dbPool)
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func save(playlistEpisodes: [PlaylistEpisode], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                let topPosition = playlistEpisodes[0].episodePosition
                let uuids = playlistEpisodes.map(\.episodeUuid)
                // move every episode after this one down , if there are any

                try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = episodePosition + ? WHERE episodePosition >= ? AND wasDeleted = 0 AND episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids)))", arguments: [playlistEpisodes.count, topPosition])

                for playlistEpisode in playlistEpisodes {
                    if playlistEpisode.id == 0 {
                        playlistEpisode.id = DBUtils.generateUniqueId()
                        try db.execute(sql: "INSERT INTO \(DataManager.playlistEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(playlistEpisode: playlistEpisode))!)
                    } else {
                        let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                        try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET \(setStatement) WHERE id = ?", arguments: StatementArguments(self.createValuesFrom(playlistEpisode: playlistEpisode, includeIdForWhere: true))!)
                    }
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.save error: \(error)")
        }
        saveOrdering(dbQueue: dbQueue, dbPool: dbPool)
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func delete(playlistEpisode: PlaylistEpisode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE id = ?", arguments: [playlistEpisode.id])
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.delete error: \(error)")
        }

        saveOrdering(dbQueue: dbQueue, dbPool: dbPool)
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func deleteAllUpNextEpisodes(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName)")
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodes error: \(error)")
        }

        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func deleteAllUpNextEpisodesExcept(episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid <> ?", arguments: [episodeUuid])
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesExcept error: \(error)")
        }

        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func deleteAllUpNextEpisodesNotIn(uuids: [String], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                if uuids.count == 0 {
                    try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName)")
                } else {
                    try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids)))")
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
        }

        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func deleteAllUpNextEpisodesIn(uuids: [String], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        guard uuids.count > 0 else { return }
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid IN (\(DataHelper.convertArrayToInString(uuids)))")
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
        }
        saveOrdering(dbQueue: dbQueue, dbPool: dbPool)
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    func movePlaylistEpisode(from: Int, to: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        var resortedItems = cachedItems

        if from == -1, to == 0 {
            // special case where we just added a new episode to the top, nothing needs to be done just redo the ordering below
        } else if let episodeToMove = resortedItems[safe: from] {
            resortedItems.remove(at: from)

            if to >= resortedItems.count {
                resortedItems.append(episodeToMove)
            } else {
                resortedItems.insert(episodeToMove, at: to)
            }
        }

        // persist index changes
        do {
            try dbPool.write { db in
                for (index, episode) in resortedItems.enumerated() {
                    try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", arguments: [index, episode.id])
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.movePlaylistEpisode error: \(error)")
        }
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    // MARK: - Up Next History (Restoring)

    public func refresh(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
    }

    // MARK: - Caching

    private func cacheEpisodes(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT * from \(DataManager.playlistEpisodeTableName) ORDER by episodePosition")

                var newItems = [PlaylistEpisode]()
                var uuids = Set<String>()
                while let row = try rows.next() {
                    let episode = self.createEpisodeFrom(row: row)
                    newItems.append(episode)
                    uuids.insert(episode.episodeUuid)
                }
                cachedItemsQueue.sync {
                    cachedItems = newItems
                    allUuids = uuids
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.cacheEpisodes error: \(error)")
        }
    }

    // MARK: - Ordering

    private func saveOrdering(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        cacheEpisodes(dbQueue: dbQueue, dbPool: dbPool)
        let sortedItems = cachedItems
        do {
            try dbPool.write { db in
                for (index, episode) in sortedItems.enumerated() {
                    try db.execute(sql: "UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", arguments: [index, episode.id])
                }
            }
        } catch {
            FileLog.shared.addMessage("UpNextDataManager.saveOrdering error: \(error)")
        }
    }

    // MARK: - Conversion

    private func createEpisodeFrom(resultSet rs: FMResultSet) -> PlaylistEpisode {
        let episode = PlaylistEpisode()

        episode.id = rs.longLongInt(forColumn: "id")
        episode.episodePosition = rs.int(forColumn: "episodePosition")
        episode.episodeUuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "episodeUuid")
        episode.title = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "title")
        episode.podcastUuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "podcastUuid")

        return episode
    }

    private func createEpisodeFrom(row: RowCursor.Element) -> PlaylistEpisode {
        let episode = PlaylistEpisode()

        episode.id = row["id"]
        episode.episodePosition = row["episodePosition"]
        episode.episodeUuid = row["episodeUuid"]
        episode.title = row["title"]
        episode.podcastUuid = row["podcastUuid"]

        return episode
    }

    private func createValuesFrom(playlistEpisode: PlaylistEpisode, includeIdForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(playlistEpisode.id)
        values.append(playlistEpisode.episodePosition)
        values.append(playlistEpisode.episodeUuid)
        values.append(UpNextDataManager.upNextPlaylistId)
        values.append(playlistEpisode.title)
        values.append(playlistEpisode.podcastUuid)

        if includeIdForWhere {
            values.append(playlistEpisode.id)
        }

        return values
    }
}
