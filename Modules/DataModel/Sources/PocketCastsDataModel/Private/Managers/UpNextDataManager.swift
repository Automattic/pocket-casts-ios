import FMDB
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

    func setup(dbQueue: FMDatabaseQueue) {
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Queries

    func allUpNextPlaylistEpisodes(dbQueue: FMDatabaseQueue) -> [PlaylistEpisode] {
        cachedItemsQueue.sync {
            cachedItems
        }
    }

    func findPlaylistEpisode(uuid: String, dbQueue: FMDatabaseQueue) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            for episode in cachedItems {
                if episode.episodeUuid == uuid {
                    return episode
                }
            }

            return nil
        }
    }

    func playlistEpisodeAt(index: Int, dbQueue: FMDatabaseQueue) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            cachedItems[safe: index]
        }
    }

    func positionForPlaylistEpisode(bottomOfList: Bool, dbQueue: FMDatabaseQueue) -> Int32 {
        cachedItemsQueue.sync {
            if bottomOfList {
                if let lastItem = cachedItems.last {
                    return lastItem.episodePosition + 1
                }
            }

            return 1
        }
    }

    func playlistEpisodeCount(dbQueue: FMDatabaseQueue) -> Int {
        cachedItemsQueue.sync {
            cachedItems.count
        }
    }

    func isEpisodePresent(uuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        cachedItemsQueue.sync {
            return allUuids.contains(uuid)
        }
    }

    // MARK: - Updates

    func save(playlistEpisode: PlaylistEpisode, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                // move every episode after this one down one, if there are any
                try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = episodePosition + 1 WHERE episodePosition >= ? AND episodeUuid != ? AND wasDeleted = 0", values: [playlistEpisode.episodePosition, playlistEpisode.episodeUuid])

                if playlistEpisode.id == 0 {
                    playlistEpisode.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.playlistEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(playlistEpisode: playlistEpisode))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(playlistEpisode: playlistEpisode, includeIdForWhere: true))
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.save error: \(error)")
            }
        }
        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func save(playlistEpisodes: [PlaylistEpisode], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                let topPosition = playlistEpisodes[0].episodePosition
                let uuids = playlistEpisodes.map(\.episodeUuid)
                // move every episode after this one down , if there are any
                db.beginTransaction()

                try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = episodePosition + ? WHERE episodePosition >= ? AND wasDeleted = 0 AND episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids)))", values: [playlistEpisodes.count, topPosition])

                for playlistEpisode in playlistEpisodes {
                    if playlistEpisode.id == 0 {
                        playlistEpisode.id = DBUtils.generateUniqueId()
                        try db.executeUpdate("INSERT INTO \(DataManager.playlistEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(playlistEpisode: playlistEpisode))
                    } else {
                        let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                        try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(playlistEpisode: playlistEpisode, includeIdForWhere: true))
                    }
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.save error: \(error)")
            }
        }
        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func delete(playlistEpisode: PlaylistEpisode, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE id = ?", values: [playlistEpisode.id])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.delete error: \(error)")
            }
        }

        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodes(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName)", values: nil)
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodes error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesExcept(episodeUuid: String, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid <> ?", values: [episodeUuid])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesExcept error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesNotIn(uuids: [String], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                if uuids.count == 0 {
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName)", values: nil)
                } else {
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids)))", values: nil)
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesIn(uuids: [String], dbQueue: FMDatabaseQueue) {
        guard uuids.count > 0 else { return }
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid IN (\(DataHelper.convertArrayToInString(uuids)))", values: nil)
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
            }
        }
        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func movePlaylistEpisode(from: Int, to: Int, dbQueue: FMDatabaseQueue) {
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
        dbQueue.inTransaction { db, _ in
            do {
                for (index, episode) in resortedItems.enumerated() {
                    try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", values: [index, episode.id])
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.movePlaylistEpisode error: \(error)")
            }
        }
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Caching

    private func cacheEpisodes(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.playlistEpisodeTableName) ORDER by episodePosition", values: nil)
                defer { resultSet.close() }

                var newItems = [PlaylistEpisode]()
                var uuids = Set<String>()
                while resultSet.next() {
                    let episode = self.createEpisodeFrom(resultSet: resultSet)
                    newItems.append(episode)
                    uuids.insert(episode.episodeUuid)
                }
                cachedItemsQueue.sync {
                    cachedItems = newItems
                    allUuids = uuids
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.cacheEpisodes error: \(error)")
            }
        }
    }

    // MARK: - Ordering

    private func saveOrdering(dbQueue: FMDatabaseQueue) {
        cacheEpisodes(dbQueue: dbQueue)
        let sortedItems = cachedItems
        dbQueue.inTransaction { db, _ in
            do {
                for (index, episode) in sortedItems.enumerated() {
                    try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", values: [index, episode.id])
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.saveOrdering error: \(error)")
            }
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
