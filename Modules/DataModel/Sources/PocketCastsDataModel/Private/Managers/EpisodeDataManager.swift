import FMDB
import PocketCastsUtils

class EpisodeDataManager {
    private let columnNames = [
        "id",
        "addedDate",
        "lastDownloadAttemptDate",
        "detailedDescription",
        "downloadErrorDetails",
        "downloadTaskId",
        "downloadUrl",
        "episodeDescription",
        "episodeStatus",
        "fileType",
        "contentType",
        "keepEpisode",
        "playedUpTo",
        "duration",
        "playingStatus",
        "autoDownloadStatus",
        "publishedDate",
        "sizeInBytes",
        "playingStatusModified",
        "playedUpToModified",
        "durationModified",
        "keepEpisodeModified",
        "title",
        "uuid",
        "podcastUuid",
        "playbackErrorDetails",
        "cachedFrameCount",
        "lastPlaybackInteractionDate",
        "lastPlaybackInteractionSyncStatus",
        "podcast_id",
        "episodeNumber",
        "seasonNumber",
        "episodeType",
        "archived",
        "archivedModified",
        "lastArchiveInteractionDate",
        "excludeFromEpisodeLimit",
        "starredModified",
        "deselectedChapters",
        "deselectedChaptersModified",
        "metadata"
    ]

    // MARK: - Query

    func findBy(uuid: String, dbQueue: FMDatabaseQueue) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE uuid = ?", values: [uuid], dbQueue: dbQueue)
    }

    func findWhere(customWhere: String, arguments: [Any]?, dbQueue: FMDatabaseQueue) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(customWhere)", values: arguments, dbQueue: dbQueue)
    }

    func findPlayedEpisodes(uuids: [String], dbQueue: FMDatabaseQueue) -> [String] {
        let list = uuids.map { "'\($0)'" }.joined(separator: ",")

        let query = """
        SELECT * from \(DataManager.episodeTableName)
        WHERE uuid IN (\(list))
        AND playingStatus = ?
        LIMIT \(uuids.count)
        """

        var episodes = [String]()
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: [PlayingStatus.completed.rawValue])
                defer { resultSet.close() }

                while resultSet.next() {
                    let uuid = DBUtils.nonNilStringFromColumn(resultSet: resultSet, columnName: "uuid")
                    episodes.append(uuid)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.loadMultiple Episode error: \(error)")
            }
        }
        return episodes
    }

    func downloadedEpisodeExists(uuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        var found = false
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT id from \(DataManager.episodeTableName) WHERE episodeStatus = ? AND uuid = ?", values: [DownloadStatus.downloaded.rawValue, uuid])
                defer { resultSet.close() }

                if resultSet.next() {
                    found = true
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeExists error: \(error)")
            }
        }

        return found
    }

    func findBy(downloadTaskId: String, dbQueue: FMDatabaseQueue) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE downloadTaskId = ?", values: [downloadTaskId], dbQueue: dbQueue)
    }

    func findWhereNotNull(columnName: String, dbQueue: FMDatabaseQueue) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(columnName) IS NOT NULL", values: nil, dbQueue: dbQueue)
    }

    func findEpisodesWhere(customWhere: String, arguments: [Any]?, dbQueue: FMDatabaseQueue) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(customWhere)", values: arguments, dbQueue: dbQueue)
    }

    func unsyncedEpisodes(limit: Int, dbQueue: FMDatabaseQueue) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE playingStatusModified > 0 OR playedUpToModified > 0 OR durationModified > 0 OR keepEpisodeModified > 0 OR archivedModified > 0 LIMIT \(limit)", values: nil, dbQueue: dbQueue)
    }

    func allEpisodesForPodcast(id: Int64, dbQueue: FMDatabaseQueue) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE podcast_id = ?", values: [id], dbQueue: dbQueue)
    }

    func episodesWithListenHistory(limit: Int, dbQueue: FMDatabaseQueue) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT \(limit)", values: nil, dbQueue: dbQueue)
    }

    func findLatestEpisode(podcast: Podcast, dbQueue: FMDatabaseQueue) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE podcast_id = ? ORDER BY publishedDate DESC, addedDate DESC LIMIT 1", values: [podcast.id], dbQueue: dbQueue)
    }

    func allUpNextEpisodes(dbQueue: FMDatabaseQueue) -> [Episode] {
        let upNextTableName = DataManager.playlistEpisodeTableName
        let episodeTableName = DataManager.episodeTableName

        return loadMultiple(query: "SELECT \(episodeTableName).* FROM \(upNextTableName) JOIN \(episodeTableName) ON \(episodeTableName).uuid = \(upNextTableName).episodeUuid ORDER BY \(upNextTableName).episodePosition ASC", values: nil, dbQueue: dbQueue)
    }

    private func loadSingle(query: String, values: [Any]?, dbQueue: FMDatabaseQueue) -> Episode? {
        var episode: Episode?
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                if resultSet.next() {
                    episode = self.createEpisodeFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.loadSingle error: \(error)")
            }
        }

        return episode
    }

    private func loadMultiple(query: String, values: [Any]?, dbQueue: FMDatabaseQueue) -> [Episode] {
        var episodes = [Episode]()
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    let episode = self.createEpisodeFrom(resultSet: resultSet)
                    episodes.append(episode)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.loadMultiple Episode error: \(error)")
            }
        }

        return episodes
    }

    func downloadedEpisodeCount(dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = Int(resultSet.int(forColumn: "Count"))
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeCount error: \(error)")
            }
        }

        return count
    }

    func failedDownloadEpisodeCount(dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloadFailed.rawValue)"
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = Int(resultSet.int(forColumn: "Count"))
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeCount error: \(error)")
            }
        }

        return count
    }

    func failedDownloadFirstDate(dbQueue: FMDatabaseQueue, sortOrder: SortOrder) -> Date? {
        let orderDirection = sortOrder == .forward ? "DESC" : "ASC"
        var date: Date?
        let query = "SELECT * from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloadFailed.rawValue) AND lastDownloadAttemptDate IS NOT NULL ORDER BY lastDownloadAttemptDate \(orderDirection) LIMIT 1"
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    date = resultSet.date(forColumn: "lastDownloadAttemptDate")
                }
            } catch {
                logError(error: error)
            }
        }

        return date
    }

    func logError(error: Error, callingFile: String = #file, callingFunction: String = #function) {
        FileLog.shared.addMessage("\((callingFile.components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? "").\(callingFunction) error: \(error)")
    }

    // MARK: - Updates

    func saveIfNotModified(starred: Bool, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        if !starred {
            saveEpisode(starredModified: 0, episodeUuid: episodeUuid, dbQueue: dbQueue)
        }
        return saveFieldIfNotModified(fieldName: "keepEpisode", modifiedFieldName: "keepEpisodeModified", value: starred, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveIfNotModified(archived: Bool, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        saveFieldIfNotModified(fieldName: "archived", modifiedFieldName: "archivedModified", value: archived, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveIfNotModified(playingStatus: PlayingStatus, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        saveFieldIfNotModified(fieldName: "playingStatus", modifiedFieldName: "playingStatusModified", value: playingStatus.rawValue, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveIfNotModified(chapters: String, remoteModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        saveFieldIfNotModified(fieldName: "deselectedChapters", modifiedFieldName: "deselectedChaptersModified", value: chapters, remoteModified: remoteModified, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func save(episode: Episode, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                if episode.id == 0 {
                    episode.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.episodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(episode: episode))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(episode: episode, includeIdForWhere: true))
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.save Episode error: \(error)")
            }
        }
    }

    func bulkSave(episodes: [Episode], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    if episode.id == 0 {
                        episode.id = DBUtils.generateUniqueId()
                        try db.executeUpdate("INSERT INTO \(DataManager.episodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(episode: episode))
                    } else {
                        let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                        try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(episode: episode, includeIdForWhere: true))
                    }
                }

                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkSave error: \(error)")
            }
        }
    }

    func bulkSetStarred(starred: Bool, episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                let firstModified = DBUtils.currentUTCTimeInMillis() + Int64(episodes.count) - 1
                for (index, episode) in episodes.enumerated() {
                    if episode.keepEpisode == starred { continue }

                    var fields = [String]()
                    var values = [Any]()

                    fields.append("keepEpisode")
                    values.append(starred)
                    if updateSyncFlag {
                        fields.append("keepEpisodeModified")
                        values.append(firstModified - Int64(index))
                    }

                    let starredModifiedValue = starred ? (firstModified - Int64(index)) : 0
                    fields.append("starredModified")
                    values.append(starredModifiedValue)

                    values.append(episode.uuid)

                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkSetStarred error: \(error)")
            }
        }
    }

    func bulkUserFileDelete(episodes: [Episode], dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    var fields = [String]()
                    var values = [Any]()

                    fields.append("episodeStatus")
                    values.append(DownloadStatus.notDownloaded.rawValue)
                    fields.append("autoDownloadStatus")
                    values.append(AutoDownloadStatus.userDeletedFile.rawValue)
                    fields.append("cachedFrameCount")
                    values.append(0)
                    values.append(episode.uuid)

                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkUserFileDelete error: \(error)")
            }
        }
    }

    func saveFileType(episode: Episode, fileType: String, dbQueue: FMDatabaseQueue) {
        episode.fileType = fileType
        save(fieldName: "fileType", value: fileType, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveFileSize(episode: Episode, fileSize: Int64, dbQueue: FMDatabaseQueue) {
        episode.sizeInBytes = fileSize
        save(fieldName: "sizeInBytes", value: fileSize, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveBulkEpisodeSyncInfo(episodes: [EpisodeBasicData], dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    guard let uuid = episode.uuid else { continue }

                    var fields = [String]()
                    var values = [Any]()
                    if let duration = episode.duration, duration > 0 {
                        fields.append("duration")
                        values.append(duration)
                    }

                    if let playingStatus = episode.playingStatus {
                        let actualStatus = PlayingStatus(rawValue: Int32(playingStatus))?.rawValue ?? PlayingStatus.notPlayed.rawValue
                        fields.append("playingStatus")
                        values.append(actualStatus)
                    }

                    if let playedUpTo = episode.playedUpTo, playedUpTo > 0 {
                        fields.append("playedUpTo")
                        values.append(playedUpTo)
                    }
                    if let isArchived = episode.isArchived {
                        fields.append("archived")
                        values.append(isArchived)

                        fields.append("lastArchiveInteractionDate")
                        values.append(Date())
                    }
                    if let starred = episode.starred {
                        fields.append("keepEpisode")
                        values.append(starred)
                    }
                    if let deselectedChapters = episode.deselectedChapters {
                        fields.append("deselectedChapters")
                        values.append(deselectedChapters)
                    }
                    values.append(uuid)

                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }

                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.saveBulkEpisodeSyncInfo error: \(error)")
            }
        }
    }

    func saveFrameCount(episodeId: Int64, frameCount: Int64, dbQueue: FMDatabaseQueue) {
        save(fieldName: "cachedFrameCount", value: frameCount, episodeId: episodeId, dbQueue: dbQueue)
    }

    func findFrameCount(episodeId: Int64, dbQueue: FMDatabaseQueue) -> Int64 {
        var frameCount = 0 as Int64

        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT cachedFrameCount from \(DataManager.episodeTableName) WHERE id = ?", values: [episodeId])
                defer { resultSet.close() }

                if resultSet.next() {
                    frameCount = resultSet.longLongInt(forColumn: "cachedFrameCount")
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.findFrameCount error: \(error)")
            }
        }

        return frameCount
    }

    func saveEpisode(playbackError: String?, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.playbackErrorDetails = playbackError
        save(fieldName: "playbackErrorDetails", value: DBUtils.replaceNilWithNull(value: episode.playbackErrorDetails), episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(playedUpTo: Double, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        episode.playedUpTo = playedUpTo
        var fields = ["playedUpTo"]
        var values = [episode.playedUpTo] as [Any]

        if updateSyncFlag {
            episode.playedUpToModified = DBUtils.currentUTCTimeInMillis()
            fields.append("playedUpToModified")
            values.append(episode.playedUpToModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func updateEpisodePlaybackInteractionDate(episode: Episode, dbQueue: FMDatabaseQueue) {
        let now = Date()
        let syncStatus = SyncStatus.notSynced.rawValue
        episode.lastPlaybackInteractionDate = now
        episode.lastPlaybackInteractionSyncStatus = syncStatus
        let fields = ["lastPlaybackInteractionDate", "lastPlaybackInteractionSyncStatus"]
        let values = [now, syncStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func clearEpisodePlaybackInteractionDate(episodeUuid: String, dbQueue: FMDatabaseQueue) {
        save(fieldName: "lastPlaybackInteractionDate", value: NSNull(), episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func setEpisodePlaybackInteractionDate(interactionDate: Date, episodeUuid: String, dbQueue: FMDatabaseQueue) {
        save(fieldName: "lastPlaybackInteractionDate", value: interactionDate, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func markAllEpisodePlaybackHistorySynced(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionSyncStatus = ?", values: [SyncStatus.synced.rawValue])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.markAllEpisodePlaybackHistorySynced error: \(error)")
            }
        }
    }

    func clearEpisodePlaybackInteractionDatesBefore(date: Date, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionDate = NULL WHERE lastPlaybackInteractionDate <= ?", values: [date])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.clearEpisodePlaybackInteractionDatesBefore error: \(error)")
            }
        }
    }

    func clearAllEpisodePlaybackInteractions(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionDate = NULL WHERE lastPlaybackInteractionDate > 0", values: [])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.clearAllEpisodePlaybackInteractions error: \(error)")
            }
        }
    }

    func saveEpisode(playingStatus: PlayingStatus, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        episode.playingStatus = playingStatus.rawValue
        var fields = ["playingStatus"]
        var values = [episode.playingStatus] as [Any]

        if updateSyncFlag {
            episode.playingStatusModified = DBUtils.currentUTCTimeInMillis()
            fields.append("playingStatusModified")
            values.append(episode.playingStatusModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(archived: Bool, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        let now = Date()
        episode.archived = archived
        episode.lastArchiveInteractionDate = now
        var fields = ["archived", "lastArchiveInteractionDate"]
        var values = [episode.archived, now] as [Any]

        if updateSyncFlag {
            episode.archivedModified = DBUtils.currentUTCTimeInMillis()
            fields.append("archivedModified")
            values.append(episode.archivedModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(excludeFromEpisodeLimit: Bool, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.excludeFromEpisodeLimit = excludeFromEpisodeLimit
        save(fieldName: "excludeFromEpisodeLimit", value: episode.excludeFromEpisodeLimit, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(duration: Double, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        episode.duration = duration
        var fields = ["duration"]
        var values = [episode.duration] as [Any]

        if updateSyncFlag {
            episode.durationModified = DBUtils.currentUTCTimeInMillis()
            fields.append("durationModified")
            values.append(episode.durationModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(starred: Bool, starredModified: Int64?, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        episode.keepEpisode = starred
        var fields = ["keepEpisode"]
        var values = [episode.keepEpisode] as [Any]

        fields.append("starredModified")
        if let starredModified = starredModified {
            values.append(starredModified)
        } else {
            let starredModifiedValue = starred ? DBUtils.currentUTCTimeInMillis() : 0
            values.append(starredModifiedValue)
        }

        if updateSyncFlag {
            episode.keepEpisodeModified = DBUtils.currentUTCTimeInMillis()
            fields.append("keepEpisodeModified")
            values.append(episode.keepEpisodeModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        save(fieldName: "episodeStatus", value: episode.episodeStatus, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, lastDownloadAttemptDate: Date, autoDownloadStatus: AutoDownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        episode.autoDownloadStatus = autoDownloadStatus.rawValue

        let fields = ["episodeStatus", "lastDownloadAttemptDate", "autoDownloadStatus"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.lastDownloadAttemptDate), episode.autoDownloadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(autoDownloadStatus: AutoDownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.autoDownloadStatus = autoDownloadStatus.rawValue
        save(fieldName: "autoDownloadStatus", value: autoDownloadStatus, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadError: String?, downloadTaskId: String?, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadErrorDetails = downloadError
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadErrorDetails", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadErrorDetails), DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadTaskId: String?, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, downloadTaskId: String?, contentType: String?, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes
        episode.downloadTaskId = downloadTaskId
        episode.contentType = contentType

        let fields = ["episodeStatus", "sizeInBytes", "contentType", "downloadTaskId"]
        let values = [episode.episodeStatus, episode.sizeInBytes, DBUtils.replaceNilWithNull(value: episode.contentType), DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, episode: Episode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes

        let fields = ["episodeStatus", "sizeInBytes"]
        let values = [episode.episodeStatus, episode.sizeInBytes, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadUrl: String, episodeUuid: String, dbQueue: FMDatabaseQueue) {
        save(fieldName: "downloadUrl", value: downloadUrl, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveEpisode(starredModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue) {
        save(fieldName: "starredModified", value: starredModified, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func clearKeepEpisodeModified(episode: Episode, dbQueue: FMDatabaseQueue) {
        let fields = ["keepEpisodeModified"]
        var values = [episode.keepEpisodeModified] as [Any]
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func clearDownloadTaskId(episode: Episode, dbQueue: FMDatabaseQueue) {
        save(fieldName: "downloadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue)
    }

    func delete(episodeUuid: String, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.episodeTableName) WHERE uuid = ?", values: [episodeUuid])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.delete error: \(error)")
            }
        }
    }

    func deleteAllEpisodesInPodcast(podcastId: Int64, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.episodeTableName) WHERE podcast_id = ?", values: [podcastId])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.deleteAllEpisodesInPodcast error: \(error)")
            }
        }
    }

    func markAllSynced(episodes: [Episode], dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET playingStatusModified = 0, playedUpToModified = 0, durationModified = 0, keepEpisodeModified = 0, archivedModified = 0 WHERE id = ?", values: [episode.id])
                }

                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.markAllSynced error: \(error)")
            }
        }
    }

    func markAllUnarchivedForPodcast(id: Int64, dbQueue: FMDatabaseQueue) {
        updateAll(fields: ["archived"], values: [false, id], whereClause: "podcast_id = ?", dbQueue: dbQueue)
    }

    func bulkMarkAsPlayed(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    if episode.playingStatus == PlayingStatus.completed.rawValue { continue }

                    var fields = [String]()
                    var values = [Any]()

                    fields.append("playingStatus")
                    values.append(PlayingStatus.completed.rawValue)

                    if updateSyncFlag {
                        fields.append("playingStatusModified")
                        values.append(DBUtils.currentUTCTimeInMillis())
                    }

                    values.append(episode.uuid)
                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkMarkAsPlayed error: \(error)")
            }
        }
    }

    func bulkMarkAsUnPlayed(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    if episode.playingStatus == PlayingStatus.notPlayed.rawValue { continue }

                    var fields = [String]()
                    var values = [Any]()

                    fields.append("playingStatus")
                    values.append(PlayingStatus.notPlayed.rawValue)
                    fields.append("playedUpTo")
                    values.append(0)
                    if updateSyncFlag {
                        fields.append("playingStatusModified")
                        values.append(DBUtils.currentUTCTimeInMillis())
                    }

                    values.append(episode.uuid)
                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkMarkAsUnPlayed error: \(error)")
            }
        }
    }

    func bulkArchive(episodes: [Episode], markAsNotDownloaded: Bool, markAsPlayed: Bool, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    var fields = [String]()
                    var values = [Any]()
                    if !episode.archived {
                        fields.append("archived")
                        values.append(true)

                        if updateSyncFlag {
                            fields.append("archivedModified")
                            values.append(DBUtils.currentUTCTimeInMillis())
                        }
                    }
                    if markAsNotDownloaded, episode.episodeStatus != DownloadStatus.notDownloaded.rawValue {
                        fields.append("episodeStatus")
                        values.append(DownloadStatus.notDownloaded.rawValue)
                        fields.append("autoDownloadStatus")
                        values.append(AutoDownloadStatus.userDeletedFile.rawValue)
                        fields.append("cachedFrameCount")
                        values.append(0)
                    }
                    if markAsPlayed, episode.playingStatus != PlayingStatus.completed.rawValue {
                        fields.append("playingStatus")
                        values.append(PlayingStatus.completed.rawValue)

                        if updateSyncFlag {
                            fields.append("playingStatusModified")
                            values.append(DBUtils.currentUTCTimeInMillis())
                        }
                    }
                    if fields.count == 0 { continue }

                    values.append(episode.uuid)

                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkArchive error: \(error)")
            }
        }
    }

    func bulkUnarchive(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    if !episode.archived { continue }

                    var fields = [String]()
                    var values = [Any]()

                    fields.append("archived")
                    values.append(false)

                    if updateSyncFlag {
                        fields.append("archivedModified")
                        values.append(DBUtils.currentUTCTimeInMillis())
                    }

                    if let podcastAutoArchiveLimit = episode.parentPodcast()?.autoArchiveEpisodeLimitCount, podcastAutoArchiveLimit > 0 {
                        fields.append("excludeFromEpisodeLimit")
                        values.append(true)
                    }
                    values.append(episode.uuid)
                    let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkUnarchive error: \(error)")
            }
        }
    }

    private func save(fields: [String], values: [Any], useId: Bool = true, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                let idColumn = useId ? "id" : "uuid"
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE \(idColumn) = ?", values: values)
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.save fields error: \(error)")
            }
        }
    }

    private func save(fieldName: String, value: Any, episodeId: Int64, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE id = ?", values: [value, episodeId])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.save field by id error: \(error)")
            }
        }
    }

    private func save(fieldName: String, value: Any, episodeUuid: String, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ?", values: [value, episodeUuid])
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.save field by uuid error: \(error)")
            }
        }
    }

    private func saveFieldIfNotModified(fieldName: String, modifiedFieldName: String, value: Any, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        var saved = false
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ? AND \(modifiedFieldName) = 0", values: [value, episodeUuid])
                saved = (db.changes > 0)
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.saveFieldIfNotModified error: \(error)")
            }
        }

        return saved
    }

    private func saveFieldIfNotModified(fieldName: String, modifiedFieldName: String, value: Any, remoteModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue) -> Bool {
        var saved = false
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ? AND \(modifiedFieldName) < ?", values: [value, episodeUuid, remoteModified])
                saved = (db.changes > 0)
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.saveFieldIfNotModified error: \(error)")
            }
        }

        return saved
    }

    private func updateAll(fields: [String], values: [Any], whereClause: String?, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                var query = "UPDATE \(DataManager.episodeTableName) SET \(fields.joined(separator: " = ?, ")) = ?"
                if let whereClause = whereClause {
                    query += " WHERE \(whereClause)"
                }
                try db.executeUpdate(query, values: values)
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.updateAll error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createEpisodeFrom(resultSet rs: FMResultSet) -> Episode {
        Episode.from(resultSet: rs)
    }

    private func createValuesFrom(episode: Episode, includeIdForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(episode.id)
        values.append(DBUtils.nullIfNil(value: episode.addedDate))
        values.append(episode.lastDownloadAttemptDate ?? Date(timeIntervalSince1970: 0))
        values.append(DBUtils.nullIfNil(value: episode.detailedDescription))
        values.append(DBUtils.nullIfNil(value: episode.downloadErrorDetails))
        values.append(DBUtils.nullIfNil(value: episode.downloadTaskId))
        values.append(DBUtils.nullIfNil(value: episode.downloadUrl))
        values.append(DBUtils.nullIfNil(value: episode.episodeDescription))
        values.append(episode.episodeStatus)
        values.append(DBUtils.nullIfNil(value: episode.fileType))
        values.append(DBUtils.nullIfNil(value: episode.contentType))
        values.append(episode.keepEpisode)
        values.append(episode.playedUpTo)
        values.append(episode.duration)
        values.append(episode.playingStatus)
        values.append(episode.autoDownloadStatus)
        values.append(DBUtils.nullIfNil(value: episode.publishedDate))
        values.append(episode.sizeInBytes)
        values.append(episode.playingStatusModified)
        values.append(episode.playedUpToModified)
        values.append(episode.durationModified)
        values.append(episode.keepEpisodeModified)
        values.append(DBUtils.nullIfNil(value: episode.title))
        values.append(episode.uuid)
        values.append(episode.podcastUuid)
        values.append(DBUtils.nullIfNil(value: episode.playbackErrorDetails))
        values.append(episode.cachedFrameCount)
        values.append(DBUtils.nullIfNil(value: episode.lastPlaybackInteractionDate))
        values.append(episode.lastPlaybackInteractionSyncStatus)
        values.append(episode.podcast_id)
        values.append(episode.episodeNumber)
        values.append(episode.seasonNumber)
        values.append(DBUtils.nullIfNil(value: episode.episodeType))
        values.append(episode.archived)
        values.append(episode.archivedModified)
        values.append(episode.lastArchiveInteractionDate ?? Date(timeIntervalSince1970: 0))
        values.append(episode.excludeFromEpisodeLimit)
        values.append(episode.starredModified)
        values.append(DBUtils.nullIfNil(value: episode.deselectedChapters))
        values.append(episode.deselectedChaptersModified)
        values.append(episode.rawMetadata as Any)

        if includeIdForWhere {
            values.append(episode.id)
        }

        return values
    }
}

#if os(watchOS)
// Only here to support watchOS 8
public enum SortOrder {
    case forward
    case reverse
}
#endif


// MARK: - 👻 Ghost Episodes 👻

extension EpisodeDataManager {
    func findGhostEpisodes(_ dbQueue: FMDatabaseQueue) -> [Episode] {
        let query = "SELECT SJEpisode.* FROM SJEpisode LEFT JOIN SJPodcast ON SJEpisode.podcastUuid = SJPodcast.uuid WHERE SJPodcast.uuid IS NULL"

        return loadMultiple(query: query, values: nil, dbQueue: dbQueue)
    }
}

// MARK: - Swift Concurrency

extension EpisodeDataManager {
    @discardableResult
    func bulkSave(showInfo: [String: String], dbQueue: FMDatabaseQueue) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.inDatabase { db in
                do {
                    db.beginTransaction()

                    for episode in showInfo {
                        try db.executeUpdate("UPDATE \(DataManager.episodeTableName) SET metadata = ? WHERE uuid = ?;", values: [episode.value, episode.key])
                    }

                    db.commit()
                    continuation.resume(returning: true)
                } catch {
                    FileLog.shared.addMessage("EpisodeDataManager.bulkSave showInfo error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func findEpisodeMetadata(uuid: String, dbQueue: FMDatabaseQueue) async throws -> Episode.Metadata? {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.inDatabase { db in
                do {
                    let resultSet = try db.executeQuery("SELECT metadata from \(DataManager.episodeTableName) WHERE uuid = ?", values: [uuid])
                    defer { resultSet.close() }

                    if resultSet.next(), let metadataData = resultSet.string(forColumn: "metadata")?.data(using: .utf8) {
                        Task {
                            let metadata = await self.getShowInfo(for: metadataData)
                            continuation.resume(returning: metadata)
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    FileLog.shared.addMessage("EpisodeDataManager.findEpisodeMetadata Episode metadata error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func findRawEpisodeMetadata(uuid: String, dbQueue: FMDatabaseQueue) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.inDatabase { db in
                do {
                    let resultSet = try db.executeQuery("SELECT metadata from \(DataManager.episodeTableName) WHERE uuid = ?", values: [uuid])
                    defer { resultSet.close() }

                    if resultSet.next() {
                        continuation.resume(returning: resultSet.string(forColumn: "metadata"))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    FileLog.shared.addMessage("EpisodeDataManager.findRawEpisodeMetadata Episode metadata error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - New Show Info

extension EpisodeDataManager {
    public func storeShowInfo(with data: Data, dbQueue: FMDatabaseQueue) async throws {
        // show notes string JSON
        var episodesToUpdate: [String: String] = [:]
        if let showInfo = try? (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?["podcast"] as? [String: Any],
           let episodes = showInfo["episodes"] as? [Any] {
            // Iterate over each episode and store it's JSON string content using the
            // episode UUID as key
            episodes.forEach { episode in
                if let uuid = (episode as? [String: Any])?["uuid"] as? String,
                   let jsonData = try? JSONSerialization.data(withJSONObject: episode),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    episodesToUpdate[uuid] = jsonString
                }
            }
        }

        try await bulkSave(showInfo: episodesToUpdate, dbQueue: dbQueue)
    }

    private func getShowInfo(for data: Data) async -> Episode.Metadata? {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Episode.Metadata.self, from: data)
        } catch {
            return nil
        }
    }
}
