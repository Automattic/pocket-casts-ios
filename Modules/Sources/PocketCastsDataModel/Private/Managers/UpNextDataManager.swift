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

    private let cache = Mutex((items: [PlaylistEpisode](), uuids: Set<String>()))

    func setup(dbQueue: GRDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Queries

    func allUpNextPlaylistEpisodes(dbQueue: GRDBQueue) -> [PlaylistEpisode] {
        cache.withLock { $0.items }
    }

    func findPlaylistEpisode(uuid: String, dbQueue: GRDBQueue) -> PlaylistEpisode? {
        cache.withLock { cache in
            for episode in cache.items {
                if episode.episodeUuid == uuid {
                    return episode
                }
            }

            return nil
        }
    }

    func playlistEpisodeAt(index: Int, dbQueue: GRDBQueue) -> PlaylistEpisode? {
        cache.withLock { $0.items[safe: index] }
    }

    func positionForPlaylistEpisode(bottomOfList: Bool, dbQueue: GRDBQueue) -> Int32 {
        cache.withLock { cache in
            if bottomOfList {
                if let lastItem = cache.items.last {
                    return lastItem.episodePosition + 1
                }
            }

            return 1
        }
    }

    func playlistEpisodeCount(dbQueue: GRDBQueue) -> Int {
        cache.withLock { $0.items.count }
    }

    func isEpisodePresent(uuid: String, dbQueue: GRDBQueue) -> Bool {
        cache.withLock { $0.uuids.contains(uuid) }
    }

    // MARK: - Updates

    func save(playlistEpisode: PlaylistEpisode, dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                // move every episode after this one down one, if there are any
                try db.executeUpdate(
                    """
                    UPDATE \(DataManager.playlistEpisodeTableName)
                    SET episodePosition = episodePosition + 1
                    WHERE episodePosition >= ?
                      AND episodeUuid != ?
                      AND wasDeleted = 0
                      AND playlist_id = ?
                    """,
                    values: [playlistEpisode.episodePosition, playlistEpisode.episodeUuid, UpNextDataManager.upNextPlaylistId]
                )

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

    func save(playlistEpisodes: [PlaylistEpisode], dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                let topPosition = playlistEpisodes[0].episodePosition
                let uuids = playlistEpisodes.map(\.episodeUuid)
                // move every episode after this one down , if there are any
                db.beginTransaction()

                try db.executeUpdate(
                    """
                    UPDATE \(DataManager.playlistEpisodeTableName)
                    SET episodePosition = episodePosition + ?
                    WHERE episodePosition >= ?
                      AND wasDeleted = 0
                      AND playlist_id = ?
                      AND episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids)))
                    """,
                    values: [playlistEpisodes.count, topPosition, UpNextDataManager.upNextPlaylistId]
                )

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

    func delete(playlistEpisode: PlaylistEpisode, dbQueue: GRDBQueue) {
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

    func deleteAllUpNextEpisodes(dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_id = ?", values: [UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodes error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesExcept(episodeUuid: String, dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid <> ? AND playlist_id = ?", values: [episodeUuid, UpNextDataManager.upNextPlaylistId])
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesExcept error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesNotIn(uuids: [String], dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                if uuids.isEmpty {
                    try db.executeUpdate(
                        "DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_id = ?",
                        values: [UpNextDataManager.upNextPlaylistId]
                    )
                } else {
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid NOT IN (\(DataHelper.convertArrayToInString(uuids))) AND playlist_id = ?", values: [UpNextDataManager.upNextPlaylistId])
                }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.deleteAllUpNextEpisodesNotIn error: \(error)")
            }
        }

        cacheEpisodes(dbQueue: dbQueue)
    }

    func deleteAllUpNextEpisodesIn(uuids: [String], dbQueue: GRDBQueue) {
        guard !uuids.isEmpty else { return }
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

    func movePlaylistEpisode(from: Int, to: Int, dbQueue: GRDBQueue) {
        var resortedItems = cache.withLock { $0.items }

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

    func refresh(dbQueue: GRDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
    }

    // MARK: - Caching

    private func cacheEpisodes(dbQueue: GRDBQueue) {
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.playlistEpisodeTableName) WHERE playlist_id = ? ORDER by episodePosition", values: [UpNextDataManager.upNextPlaylistId])

                var newItems = [PlaylistEpisode]()
                var uuids = Set<String>()
                while resultSet.next() {
                    let episode = self.createEpisodeFrom(resultSet: resultSet)
                    newItems.append(episode)
                    uuids.insert(episode.episodeUuid)
                }
                cache.withLock { $0 = (newItems, uuids) }
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.cacheEpisodes error: \(error)")
            }
        }
    }

    // MARK: - Ordering

    private func saveOrdering(dbQueue: GRDBQueue) {
        cacheEpisodes(dbQueue: dbQueue)
        let sortedItems = cache.withLock { $0.items }
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
