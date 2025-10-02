import PocketCastsUtils

class PlaylistDataManager {
    private let columnNames = [
        "id",
        "autoDownloadEpisodes",
        "customIcon",
        "filterAllPodcasts",
        "filterAudioVideoType",
        "filterDownloaded",
        "filterFinished",
        "filterNotDownloaded",
        "filterPartiallyPlayed",
        "filterStarred",
        "filterUnplayed",
        "filterHours",
        "playlistName",
        "sortPosition",
        "sortType",
        "uuid",
        "podcastUuids",
        "autoDownloadLimit",
        "syncStatus",
        "wasDeleted",
        "filterDuration",
        "longerThan",
        "shorterThan",
        "manual"
    ]

    func count(includeDeleted: Bool, dbQueue: PCDBQueue) -> Int {
        var count = 0
        dbQueue.read { db in
            do {
                let query: String
                if FeatureFlag.playlistsRebranding.enabled {
                    query = includeDeleted ? "SELECT COUNT(*) from \(DataManager.playlistsTableName)" : "SELECT COUNT(*) from \(DataManager.playlistsTableName) WHERE wasDeleted = 0"
                } else {
                    query = includeDeleted ? "SELECT COUNT(*) from \(DataManager.playlistsTableName) WHERE manual = 0" : "SELECT COUNT(*) from \(DataManager.playlistsTableName) WHERE manual = 0 AND wasDeleted = 0"
                }
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.count error: \(error)")
            }
        }
        return count
    }

    func episodeCount(for playlist: EpisodeFilter, episodeUuidToAdd: String?, dbQueue: PCDBQueue) -> Int {
        var count = 0
        dbQueue.read { db in
            do {
                let queryForPlaylist = PlaylistQueryBuilder.queryFor(filter: playlist, episodeUuidToAdd: episodeUuidToAdd, limit: 0)
                let resultSet = try db.executeQuery("SELECT COUNT(*) from SJEpisode WHERE \(queryForPlaylist)", values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.episodeCount error: \(error)")
            }
        }

        return count
    }

    func playlistEpisodeCount(for playlist: EpisodeFilter, episodeUuidToAdd: String?, dbQueue: PCDBQueue) -> Int {
        var count = 0
        dbQueue.read { db in
            do {
                let query = PlaylistQueryBuilder.query(clause: .episodeCount, for: playlist, episodeUuidToAdd: episodeUuidToAdd)
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.smartPlaylistEpisodeCount error: \(error)")
            }
        }

        return count
    }

    func playlistContainsPodcast(podcastUuid: String, includeDeleted: Bool = false, dbQueue: PCDBQueue) -> Bool {
        var exists = false
        dbQueue.read { db in
            do {
                let query = PlaylistQueryBuilder.podcastExistsInPlaylistEpisodesQuery(includeDeleted: includeDeleted)
                let resultSet = try db.executeQuery(query, values: [podcastUuid])
                defer { resultSet.close() }

                exists = resultSet.next()
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.playlistContainsPodcast error: \(error)")
            }
        }

        return exists
    }

    func allPlaylists(includeDeleted: Bool, dbQueue: PCDBQueue) -> [EpisodeFilter] {
        let query: String
        if FeatureFlag.playlistsRebranding.enabled {
            query = includeDeleted ? "SELECT * from \(DataManager.playlistsTableName) ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.playlistsTableName) WHERE wasDeleted = 0 ORDER BY sortPosition ASC"
        } else {
            query = includeDeleted ? "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 0 ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 0 AND wasDeleted = 0 ORDER BY sortPosition ASC"
        }
        return allPlaylists(query: query, values: nil, dbQueue: dbQueue)
    }

    func allSmartPlaylists(includeDeleted: Bool, dbQueue: PCDBQueue) -> [EpisodeFilter] {
        let query = includeDeleted ? "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 0 ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 0 AND wasDeleted = 0 ORDER BY sortPosition ASC"
        return allPlaylists(query: query, values: nil, dbQueue: dbQueue)
    }

    func allManualPlaylists(includeDeleted: Bool, dbQueue: PCDBQueue) -> [EpisodeFilter] {
        let query = includeDeleted ? "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 1 ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.playlistsTableName) WHERE manual = 1 AND wasDeleted = 0 ORDER BY sortPosition ASC"
        return allPlaylists(query: query, values: nil, dbQueue: dbQueue)
    }

    func findBy(uuid: String, dbQueue: PCDBQueue) -> EpisodeFilter? {
        var playlist: EpisodeFilter?
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.playlistsTableName) WHERE uuid = ?", values: [uuid])
                defer { resultSet.close() }

                if resultSet.next() {
                    playlist = self.createPlaylistFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.findBy error: \(error)")
            }
        }

        return playlist
    }

    func deleteDeletedPlaylists(dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistsTableName) WHERE wasDeleted = 1", values: nil)
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.deleteDeletedPlaylists error: \(error)")
            }
        }
    }

    func allUnsyncedPlaylists(dbQueue: PCDBQueue) -> [EpisodeFilter] {
        allPlaylists(query: "SELECT * from \(DataManager.playlistsTableName) WHERE syncStatus = ? ORDER BY sortPosition ASC", values: [SyncStatus.notSynced.rawValue], dbQueue: dbQueue)
    }

    func playlistContainsEpisode(episodeUuid: String, includeDeleted: Bool, dbQueue: PCDBQueue) -> Bool {
        var exists = false
        dbQueue.read { db in
            do {
                let query: String
                if includeDeleted {
                    query = "SELECT 1 FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid = ? AND playlist_uuid IS NOT NULL LIMIT 1"
                } else {
                    query = "SELECT 1 FROM \(DataManager.playlistEpisodeTableName) WHERE episodeUuid = ? AND wasDeleted = 0 AND playlist_uuid IS NOT NULL LIMIT 1"
                }

                let resultSet = try db.executeQuery(query, values: [episodeUuid])
                defer { resultSet.close() }

                exists = resultSet.next()
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.playlistContainsEpisode error: \(error)")
            }
        }

        return exists
    }

    func manualPlaylistUUIDs(for episodeUUID: String, dbQueue: PCDBQueue) -> [String] {
        var uuids: [String] = []
        dbQueue.read { db in
            do {
                let query = """
                        SELECT playlist_uuid
                        FROM \(DataManager.playlistEpisodeTableName)
                        WHERE episodeUuid = ?
                        GROUP BY playlist_uuid
                    """
                let resultSet = try db.executeQuery(query, values: [episodeUUID])
                defer { resultSet.close() }

                while resultSet.next() {
                    if let uuid = resultSet.string(forColumn: "playlist_uuid") {
                        uuids.append(uuid)
                    }
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.manualPlaylistUUIDs error: \(error)")
            }
        }
        return uuids
    }

    func updatePosition(playlist: EpisodeFilter, newPosition: Int32, dbQueue: PCDBQueue) {
        playlist.sortPosition = newPosition
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        dbQueue.write { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET sortPosition = ?, syncStatus = ? WHERE uuid = ?", values: [playlist.sortPosition, playlist.syncStatus, playlist.uuid])
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.updatePosition error: \(error)")
            }
        }
    }

    /// Reorder a specific episode within a manual playlist to a new index
    func moveEpisode(_ episodeUuid: String, in playlist: EpisodeFilter, to newIndex: Int, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                // Load existing order (id + episodeUuid) for this playlist
                let rs = try db.executeQuery("SELECT id, episodeUuid FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? ORDER BY episodePosition ASC", values: [playlist.uuid])
                defer { rs.close() }

                var items = [(id: Int64, uuid: String)]()
                while rs.next() {
                    items.append((id: rs.longLongInt(forColumn: "id"), uuid: DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "episodeUuid")))
                }

                guard let currentIndex = items.firstIndex(where: { $0.uuid == episodeUuid }) else { return }

                let clampedTargetIndex = newIndex.clamped(to: 0...max(items.count - 1, 0))
                if clampedTargetIndex == currentIndex { return }

                var reordered = items
                let element = reordered.remove(at: currentIndex)
                let clampedIndex = newIndex.clamped(to: 0...reordered.count)
                reordered.insert(element, at: clampedIndex)

                // Persist new positions
                for (index, item) in reordered.enumerated() {
                    try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", values: [index, item.id])
                }

                playlist.syncStatus = SyncStatus.notSynced.rawValue
                try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET syncStatus = ? WHERE uuid = ?", values: [playlist.syncStatus, playlist.uuid])
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.moveEpisode error: \(error)")
            }
        }
    }

    /// Set a specific position for an episode within a manual playlist.
    /// This is equivalent to calling moveEpisode to the given index.
    func updateEpisodePosition(_ episodeUuid: String, in playlist: EpisodeFilter, to position: Int32, dbQueue: PCDBQueue) {
        moveEpisode(episodeUuid, in: playlist, to: Int(position), dbQueue: dbQueue)
    }

    /// Delete specific episodes from a manual playlist and reindex remaining items
    func deleteEpisodes(_ episodeUuids: [String], from playlist: EpisodeFilter, dbQueue: PCDBQueue) {
        guard !episodeUuids.isEmpty else { return }
        dbQueue.write { db in
            do {
                let inClause = DataHelper.convertArrayToInString(episodeUuids)
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? AND episodeUuid IN (\(inClause))", values: [playlist.uuid])
                let removedCount = db.changes
                if removedCount == 0 { return }

                // Reindex remaining
                let rs = try db.executeQuery("SELECT id FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? ORDER BY episodePosition ASC", values: [playlist.uuid])
                defer { rs.close() }
                var ids = [Int64]()
                while rs.next() { ids.append(rs.longLongInt(forColumn: "id")) }
                for (index, id) in ids.enumerated() {
                    try db.executeUpdate("UPDATE \(DataManager.playlistEpisodeTableName) SET episodePosition = ? WHERE id = ?", values: [index, id])
                }

                playlist.syncStatus = SyncStatus.notSynced.rawValue
                try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET syncStatus = ? WHERE uuid = ?", values: [playlist.syncStatus, playlist.uuid])
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.deleteEpisodes error: \(error)")
            }
        }
    }

    /// Delete all playlist-episode relationships for the given playlist
    func deleteAllEpisodes(in playlist: EpisodeFilter, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? OR playlist_id = ?", values: [playlist.uuid, playlist.id])

                let removedCount = db.changes
                if removedCount > 0 {
                    playlist.syncStatus = SyncStatus.notSynced.rawValue
                    try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET syncStatus = ? WHERE uuid = ?", values: [playlist.syncStatus, playlist.uuid])
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.deleteAllEpisodes error: \(error)")
            }
        }
    }

    func save(playlist: EpisodeFilter, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                if playlist.id == 0 {
                    playlist.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.playlistsTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(playlist: playlist))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET \(setStatement) WHERE uuid = ?", values: self.createValuesFrom(playlist: playlist, includeUuidForWhere: true))
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.save error: \(error)")
            }
        }
    }

    func delete(playlist: EpisodeFilter, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.playlistsTableName) WHERE uuid = ?", values: [playlist.uuid])
                try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? OR playlist_id = ?", values: [playlist.uuid, playlist.id])
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.delete error: \(error)")
            }
        }
    }

    func markAllSynced(dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET syncStatus = ? WHERE syncStatus = ?", values: [SyncStatus.synced.rawValue, SyncStatus.notSynced.rawValue])
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.markAllSynced error: \(error)")
            }
        }
    }

    func markAllUnsynced(dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.playlistsTableName) SET syncStatus = ? WHERE syncStatus = ?", values: [SyncStatus.notSynced.rawValue, SyncStatus.synced.rawValue])
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.markAllUnsynced error: \(error)")
            }
        }
    }

    private func allPlaylists(query: String, values: [Any]?, dbQueue: PCDBQueue) -> [EpisodeFilter] {
        var allPlaylists = [EpisodeFilter]()
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    let filter = self.createPlaylistFrom(resultSet: resultSet)
                    allPlaylists.append(filter)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.allPlaylists error: \(error)")
            }
        }
        return allPlaylists
    }

    func nextSortPositionForPlaylist(dbQueue: PCDBQueue) -> Int {
        var highestPosition = 0
        dbQueue.read { db in
            do {
                let query = "SELECT MAX(sortPosition) from \(DataManager.playlistsTableName)"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    highestPosition = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("PlaylistDataManager.nextSortPositionForPlaylist error: \(error)")
            }
        }

        return highestPosition + 1
    }

    func add(episodes: [Episode], to playlist: EpisodeFilter, dbQueue: PCDBQueue) {
        // Ensure the filter exists and has a valid id before inserting playlist items
        if playlist.id == 0 {
            save(playlist: playlist, dbQueue: dbQueue)
        }

        guard episodes.count > 0 else { return }

        dbQueue.write { db in
            do {
                // Find current max position for this playlist (by playlist_uuid)
                var startPosition: Int32 = 0
                do {
                    let rs = try db.executeQuery("SELECT COALESCE(MAX(episodePosition), 0) FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ?", values: [playlist.uuid])
                    defer { rs.close() }
                    if rs.next() {
                        startPosition = rs.int(forColumnIndex: 0)
                    }
                }

                var nextPosition = startPosition

                // Insert each episode, avoiding duplicates for this playlist
                for episode in episodes {
                    // Ensure uniqueness within this playlist
                    try db.executeUpdate("DELETE FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? AND episodeUuid = ?", values: [playlist.uuid, episode.uuid])

                    nextPosition += 1
                    let insertColumns = [
                        "id",
                        "episodePosition",
                        "episodeUuid",
                        "playlist_id",
                        "title",
                        "podcastUuid",
                        "playlist_uuid"
                    ].joined(separator: ",")

                    let values: [Any] = [
                        DBUtils.generateUniqueId(),
                        nextPosition,
                        episode.uuid,
                        playlist.id,
                        episode.displayableTitle(),
                        episode.podcastUuid,
                        playlist.uuid
                    ]

                    try db.executeUpdate("INSERT INTO \(DataManager.playlistEpisodeTableName) (\(insertColumns)) VALUES (?,?,?,?,?,?,?)", values: values)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.addEpisodes error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createPlaylistFrom(resultSet rs: PCDBResultSet) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.id = rs.longLongInt(forColumn: "id")
        playlist.autoDownloadEpisodes = rs.bool(forColumn: "autoDownloadEpisodes")
        playlist.customIcon = rs.int(forColumn: "customIcon")
        playlist.filterAllPodcasts = rs.bool(forColumn: "filterAllPodcasts")
        playlist.filterAudioVideoType = rs.int(forColumn: "filterAudioVideoType")
        playlist.filterDownloaded = rs.bool(forColumn: "filterDownloaded")
        playlist.filterFinished = rs.bool(forColumn: "filterFinished")
        playlist.filterNotDownloaded = rs.bool(forColumn: "filterNotDownloaded")
        playlist.filterPartiallyPlayed = rs.bool(forColumn: "filterPartiallyPlayed")
        playlist.filterStarred = rs.bool(forColumn: "filterStarred")
        playlist.filterUnplayed = rs.bool(forColumn: "filterUnplayed")
        playlist.filterHours = rs.int(forColumn: "filterHours")
        playlist.playlistName = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "playlistName")
        playlist.sortPosition = rs.int(forColumn: "sortPosition")
        playlist.sortType = rs.int(forColumn: "sortType")
        playlist.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        playlist.podcastUuids = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "podcastUuids")
        playlist.autoDownloadLimit = rs.int(forColumn: "autoDownloadLimit")
        playlist.syncStatus = rs.int(forColumn: "syncStatus")
        playlist.wasDeleted = rs.bool(forColumn: "wasDeleted")
        playlist.filterDuration = rs.bool(forColumn: "filterDuration")
        playlist.longerThan = rs.int(forColumn: "longerThan")
        playlist.shorterThan = rs.int(forColumn: "shorterThan")
        playlist.manual = rs.bool(forColumn: "manual")

        return playlist
    }

    private func createValuesFrom(playlist: EpisodeFilter, includeUuidForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(playlist.id)
        values.append(playlist.autoDownloadEpisodes)
        values.append(playlist.customIcon)
        values.append(playlist.filterAllPodcasts)
        values.append(playlist.filterAudioVideoType)
        values.append(playlist.filterDownloaded)
        values.append(playlist.filterFinished)
        values.append(playlist.filterNotDownloaded)
        values.append(playlist.filterPartiallyPlayed)
        values.append(playlist.filterStarred)
        values.append(playlist.filterUnplayed)
        values.append(playlist.filterHours)
        values.append(playlist.playlistName)
        values.append(playlist.sortPosition)
        values.append(playlist.sortType)
        values.append(playlist.uuid)
        values.append(playlist.podcastUuids)
        values.append(playlist.autoDownloadLimit)
        values.append(playlist.syncStatus)
        values.append(playlist.wasDeleted)
        values.append(playlist.filterDuration)
        values.append(playlist.longerThan)
        values.append(playlist.shorterThan)
        values.append(playlist.manual)

        if includeUuidForWhere {
            values.append(playlist.uuid)
        }

        return values
    }
}
