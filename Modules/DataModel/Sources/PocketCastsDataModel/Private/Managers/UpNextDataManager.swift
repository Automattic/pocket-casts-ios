import PocketCastsUtils
import Foundation

class UpNextDataManager {
    static let upNextPlaylistId = 1

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

    func setup(dbQueue: PCDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Queries

    func allUpNextPlaylistEpisodes(dbQueue: PCDBQueue) -> [PlaylistEpisode] {
        cachedItemsQueue.sync {
            cachedItems
        }
    }

    func findPlaylistEpisode(uuid: String, dbQueue: PCDBQueue) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            for episode in cachedItems {
                if episode.episodeUuid == uuid {
                    return episode
                }
            }

            return nil
        }
    }

    func playlistEpisodeAt(index: Int, dbQueue: PCDBQueue) -> PlaylistEpisode? {
        cachedItemsQueue.sync {
            cachedItems[safe: index]
        }
    }

    func positionForPlaylistEpisode(bottomOfList: Bool, dbQueue: PCDBQueue) -> Int32 {
        cachedItemsQueue.sync {
            if bottomOfList {
                if let lastItem = cachedItems.last {
                    return lastItem.episodePosition + 1
                }
            }

            return 1
        }
    }

    func playlistEpisodeCount(dbQueue: PCDBQueue) -> Int {
        cachedItemsQueue.sync {
            cachedItems.count
        }
    }

    func isEpisodePresent(uuid: String, dbQueue: PCDBQueue) -> Bool {
        cachedItemsQueue.sync {
            return allUuids.contains(uuid)
        }
    }

    // MARK: - Updates

    func save(playlistEpisode: PlaylistEpisode, dbQueue: PCDBQueue) {
        dbQueue.write { db in
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

    func save(playlistEpisodes: [PlaylistEpisode], dbQueue: PCDBQueue) {
        dbQueue.write { db in
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

    func delete(playlistEpisode: PlaylistEpisode, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE id = ? AND playlist_id = ?", values: [playlistEpisode.id, UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.delete error: \(error)")
            }
        }

        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodes(dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_id = ?", values: [UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodes error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesExcept(episodeUuid: String, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid <> ? AND playlist_id = ?", values: [episodeUuid, UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesExcept error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesNotIn(uuids: [String], dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                if uuids.count == 0 {
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName)", values: nil)
                } else {
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids))) AND playlist_id = ?", values: [UpNextDataManager.upNextPlaylistId])
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesIn(uuids: [String], dbQueue: PCDBQueue) {
        guard uuids.count > 0 else { return }
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid IN (\(DataHelper.convertArrayToInString(uuids))) AND playlist_id = ?", values: [UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
            }
        }
        saveOrdering(dbQueue: dbQueue)
        cacheEpisodes(dbQueue: dbQueue)
    }

    func movePlaylistEpisode(from: Int, to: Int, dbQueue: PCDBQueue) {
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
        dbQueue.write { db in
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

    // MARK: - Up Next History (Restoring)

    public func refresh(dbQueue: PCDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Caching

    private func cacheEpisodes(dbQueue: PCDBQueue) {
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.playlistEpisodeTableName) WHERE playlist_id = ? ORDER by episodePosition", values: [UpNextDataManager.upNextPlaylistId])
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

    private func saveOrdering(dbQueue: PCDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
        let sortedItems = cachedItems
        dbQueue.write { db in
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

    private func createEpisodeFrom(resultSet rs: PCDBResultSet) -> PlaylistEpisode {
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
