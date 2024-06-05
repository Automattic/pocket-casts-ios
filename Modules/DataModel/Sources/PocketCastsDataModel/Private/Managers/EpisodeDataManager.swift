import FMDB
import PocketCastsUtils
import GRDB

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
        "deselectedChaptersModified"
    ]

    // MARK: - Query

    func findBy(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE uuid = ?", values: [uuid], dbQueue: dbQueue, dbPool: dbPool)
    }

    func findWhere(customWhere: String, arguments: [Any]?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(customWhere)", values: arguments, dbQueue: dbQueue, dbPool: dbPool)
    }

    func findPlayedEpisodes(uuids: [String], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [String] {
        let list = uuids.map { "'\($0)'" }.joined(separator: ",")

        let query = """
        SELECT * from \(DataManager.episodeTableName)
        WHERE uuid IN (\(list))
        AND playingStatus = ?
        LIMIT \(uuids.count)
        """

        var episodes = [String]()
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query, arguments: [PlayingStatus.completed.rawValue])

                while let row = try rows.next() {
                    let uuid: String = row["uuid"]
                    episodes.append(uuid)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.loadMultiple Episode error: \(error)")
        }
        return episodes
    }

    func downloadedEpisodeExists(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        var found = false
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT id from \(DataManager.episodeTableName) WHERE episodeStatus = ? AND uuid = ?", arguments: [DownloadStatus.downloaded.rawValue, uuid])

                if let row = try rows.next() {
                    found = true
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeExists error: \(error)")
        }

        return found
    }

    func findBy(downloadTaskId: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE downloadTaskId = ?", values: [downloadTaskId], dbQueue: dbQueue, dbPool: dbPool)
    }

    func findWhereNotNull(columnName: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(columnName) IS NOT NULL", values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }

    func findEpisodesWhere(customWhere: String, arguments: [Any]?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE \(customWhere)", values: arguments, dbQueue: dbQueue, dbPool: dbPool)
    }

    func unsyncedEpisodes(limit: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE playingStatusModified > 0 OR playedUpToModified > 0 OR durationModified > 0 OR keepEpisodeModified > 0 OR archivedModified > 0 LIMIT \(limit)", values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }

    func allEpisodesForPodcast(id: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE podcast_id = ?", values: [id], dbQueue: dbQueue, dbPool: dbPool)
    }

    func episodesWithListenHistory(limit: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        loadMultiple(query: "SELECT * from \(DataManager.episodeTableName) WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT \(limit)", values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }

    func findLatestEpisode(podcast: Podcast, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Episode? {
        loadSingle(query: "SELECT * from \(DataManager.episodeTableName) WHERE podcast_id = ? ORDER BY publishedDate DESC, addedDate DESC LIMIT 1", values: [podcast.id], dbQueue: dbQueue, dbPool: dbPool)
    }

    func allUpNextEpisodes(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        let upNextTableName = DataManager.playlistEpisodeTableName
        let episodeTableName = DataManager.episodeTableName

        return loadMultiple(query: "SELECT \(episodeTableName).* FROM \(upNextTableName) JOIN \(episodeTableName) ON \(episodeTableName).uuid = \(upNextTableName).episodeUuid ORDER BY \(upNextTableName).episodePosition ASC", values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }

    private func loadSingle(query: String, values: [Any]?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Episode? {
        var episode: Episode?
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query, arguments: StatementArguments(values ?? [])!)

                if let row = try rows.next() {
                    episode = self.createEpisodeFrom(row: row)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.loadSingle error: \(error)")
        }

        return episode
    }

    private func loadMultiple(query: String, values: [Any]?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        var episodes = [Episode]()
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query, arguments: StatementArguments(values ?? [])!)

                while let row = try rows.next() {
                    let episode = self.createEpisodeFrom(row: row)
                    episodes.append(episode)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.loadSingle error: \(error)")
        }

        return episodes
    }

    func downloadedEpisodeCount(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query)

                if let row = try rows.next() {
                    count = row["Count"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeCount error: \(error)")
        }

        return count
    }

    func failedDownloadEpisodeCount(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloadFailed.rawValue)"
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query)

                if let row = try rows.next() {
                    count = row["Count"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.downloadedEpisodeCount error: \(error)")
        }

        return count
    }

    func failedDownloadFirstDate(dbQueue: FMDatabaseQueue, sortOrder: SortOrder, dbPool: DatabasePool) -> Date? {
        let orderDirection = sortOrder == .forward ? "DESC" : "ASC"
        var date: Date?
        let query = "SELECT * from \(DataManager.episodeTableName) WHERE episodeStatus = \(DownloadStatus.downloadFailed.rawValue) AND lastDownloadAttemptDate IS NOT NULL ORDER BY lastDownloadAttemptDate \(orderDirection) LIMIT 1"
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query)

                if let row = try rows.next() {
                    date = row["lastDownloadAttemptDate"]
                }
            }
        } catch {
            logError(error: error)
        }

        return date
    }

    func logError(error: Error, callingFile: String = #file, callingFunction: String = #function) {
        FileLog.shared.addMessage("\((callingFile.components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? "").\(callingFunction) error: \(error)")
    }

    // MARK: - Updates

    func saveIfNotModified(starred: Bool, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        if !starred {
            saveEpisode(starredModified: 0, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
        }
        return saveFieldIfNotModified(fieldName: "keepEpisode", modifiedFieldName: "keepEpisodeModified", value: starred, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveIfNotModified(archived: Bool, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        saveFieldIfNotModified(fieldName: "archived", modifiedFieldName: "archivedModified", value: archived, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveIfNotModified(playingStatus: PlayingStatus, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        saveFieldIfNotModified(fieldName: "playingStatus", modifiedFieldName: "playingStatusModified", value: playingStatus.rawValue, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveIfNotModified(chapters: String, remoteModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        saveFieldIfNotModified(fieldName: "deselectedChapters", modifiedFieldName: "deselectedChaptersModified", value: chapters, remoteModified: remoteModified, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func save(episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                if episode.id == 0 {
                    episode.id = DBUtils.generateUniqueId()
                    try db.execute(sql: "INSERT INTO \(DataManager.episodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(episode: episode))!)
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(setStatement) WHERE id = ?", arguments: StatementArguments(self.createValuesFrom(episode: episode, includeIdForWhere: true))!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.save Episode error: \(error)")
        }
    }

    func bulkSave(episodes: [Episode], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                for episode in episodes {
                    if episode.id == 0 {
                        episode.id = DBUtils.generateUniqueId()
                        try db.execute(sql: "INSERT INTO \(DataManager.episodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(episode: episode))!)
                    } else {
                        let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                        try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(setStatement) WHERE id = ?", arguments: StatementArguments(self.createValuesFrom(episode: episode, includeIdForWhere: true))!)
                    }
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkSave error: \(error)")
        }
    }

    func bulkSetStarred(starred: Bool, episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkSetStarred error: \(error)")
        }
    }

    func bulkUserFileDelete(episodes: [Episode], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkUserFileDelete error: \(error)")
        }
    }

    func saveFileType(episode: Episode, fileType: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.fileType = fileType
        save(fieldName: "fileType", value: fileType, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveContentType(episode: Episode, contentType: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.contentType = contentType
        save(fieldName: "contentType", value: contentType, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveFileSize(episode: Episode, fileSize: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.sizeInBytes = fileSize
        save(fieldName: "sizeInBytes", value: fileSize, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveBulkEpisodeSyncInfo(episodes: [EpisodeBasicData], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.saveBulkEpisodeSyncInfo error: \(error)")
        }
    }

    func saveFrameCount(episodeId: Int64, frameCount: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "cachedFrameCount", value: frameCount, episodeId: episodeId, dbQueue: dbQueue, dbPool: dbPool)
    }

    func findFrameCount(episodeId: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int64 {
        var frameCount = 0 as Int64

        do {
            try dbPool.write { db in

                let rows = try Row.fetchCursor(db, sql: "SELECT cachedFrameCount from \(DataManager.episodeTableName) WHERE id = ?", arguments: [episodeId])

                if let row = try rows.next() {
                    frameCount = row["cachedFrameCount"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.findFrameCount error: \(error)")
        }

        return frameCount
    }

    func saveEpisode(playbackError: String?, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.playbackErrorDetails = playbackError
        save(fieldName: "playbackErrorDetails", value: episode.playbackErrorDetails, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(playedUpTo: Double, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.playedUpTo = playedUpTo
        var fields = ["playedUpTo"]
        var values = [episode.playedUpTo] as [Any]

        if updateSyncFlag {
            episode.playedUpToModified = DBUtils.currentUTCTimeInMillis()
            fields.append("playedUpToModified")
            values.append(episode.playedUpToModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateEpisodePlaybackInteractionDate(episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        let now = Date()
        let syncStatus = SyncStatus.notSynced.rawValue
        episode.lastPlaybackInteractionDate = now
        episode.lastPlaybackInteractionSyncStatus = syncStatus
        let fields = ["lastPlaybackInteractionDate", "lastPlaybackInteractionSyncStatus"]
        let values = [now, syncStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func clearEpisodePlaybackInteractionDate(episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "lastPlaybackInteractionDate", value: NSNull(), episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func setEpisodePlaybackInteractionDate(interactionDate: Date, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "lastPlaybackInteractionDate", value: interactionDate, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func markAllEpisodePlaybackHistorySynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionSyncStatus = ?", arguments: [SyncStatus.synced.rawValue])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.markAllEpisodePlaybackHistorySynced error: \(error)")
        }
    }

    func clearEpisodePlaybackInteractionDatesBefore(date: Date, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionDate = NULL WHERE lastPlaybackInteractionDate <= ?", arguments: [date])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.clearEpisodePlaybackInteractionDatesBefore error: \(error)")
        }
    }

    func clearAllEpisodePlaybackInteractions(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET lastPlaybackInteractionDate = NULL WHERE lastPlaybackInteractionDate > 0", arguments: [])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.clearAllEpisodePlaybackInteractions error: \(error)")
        }
    }

    func saveEpisode(playingStatus: PlayingStatus, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.playingStatus = playingStatus.rawValue
        var fields = ["playingStatus"]
        var values = [episode.playingStatus] as [Any]

        if updateSyncFlag {
            episode.playingStatusModified = DBUtils.currentUTCTimeInMillis()
            fields.append("playingStatusModified")
            values.append(episode.playingStatusModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(archived: Bool, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
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

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(excludeFromEpisodeLimit: Bool, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.excludeFromEpisodeLimit = excludeFromEpisodeLimit
        save(fieldName: "excludeFromEpisodeLimit", value: episode.excludeFromEpisodeLimit, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(duration: Double, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.duration = duration
        var fields = ["duration"]
        var values = [episode.duration] as [Any]

        if updateSyncFlag {
            episode.durationModified = DBUtils.currentUTCTimeInMillis()
            fields.append("durationModified")
            values.append(episode.durationModified)
        }
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(starred: Bool, starredModified: Int64?, episode: Episode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
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

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadStatus: DownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.episodeStatus = downloadStatus.rawValue
        save(fieldName: "episodeStatus", value: episode.episodeStatus, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadStatus: DownloadStatus, lastDownloadAttemptDate: Date, autoDownloadStatus: AutoDownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        episode.autoDownloadStatus = autoDownloadStatus.rawValue

        let fields = ["episodeStatus", "lastDownloadAttemptDate", "autoDownloadStatus"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.lastDownloadAttemptDate), episode.autoDownloadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(autoDownloadStatus: AutoDownloadStatus, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.autoDownloadStatus = autoDownloadStatus.rawValue
        save(fieldName: "autoDownloadStatus", value: autoDownloadStatus.rawValue, episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadError: String?, downloadTaskId: String?, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadErrorDetails = downloadError
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadErrorDetails", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadErrorDetails), DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadTaskId: String?, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, downloadTaskId: String?, episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "sizeInBytes", "downloadTaskId"]
        let values = [episode.episodeStatus, episode.sizeInBytes, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(downloadUrl: String, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "downloadUrl", value: downloadUrl, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveEpisode(starredModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "starredModified", value: starredModified, episodeUuid: episodeUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func clearKeepEpisodeModified(episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        let fields = ["keepEpisodeModified"]
        var values = [episode.keepEpisodeModified] as [Any]
        values.append(episode.id)

        save(fields: fields, values: values, dbQueue: dbQueue, dbPool: dbPool)
    }

    func clearDownloadTaskId(episode: Episode, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        save(fieldName: "downloadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue, dbPool: dbPool)
    }

    func delete(episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.episodeTableName) WHERE uuid = ?", arguments: [episodeUuid])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.delete error: \(error)")
        }
    }

    func deleteAllEpisodesInPodcast(podcastId: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.episodeTableName) WHERE podcast_id = ?", arguments: [podcastId])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.deleteAllEpisodesInPodcast error: \(error)")
        }
    }

    func markAllSynced(episodes: [Episode], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
                for episode in episodes {
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET playingStatusModified = 0, playedUpToModified = 0, durationModified = 0, keepEpisodeModified = 0, archivedModified = 0 WHERE id = ?", arguments: [episode.id])
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.markAllSynced error: \(error)")
        }
    }

    func markAllUnarchivedForPodcast(id: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        updateAll(fields: ["archived"], values: [false, id], whereClause: "podcast_id = ?", dbQueue: dbQueue, dbPool: dbPool)
    }

    func bulkMarkAsPlayed(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkMarkAsPlayed error: \(error)")
        }
    }

    func bulkMarkAsUnPlayed(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        dbQueue.inDatabase { db in
            do {
                try dbPool.write { db in
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
                        try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                    }
                }
            } catch {
                FileLog.shared.addMessage("EpisodeDataManager.bulkMarkAsUnPlayed error: \(error)")
            }
        }
    }

    func bulkArchive(episodes: [Episode], markAsNotDownloaded: Bool, markAsPlayed: Bool, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkArchive error: \(error)")
        }
    }

    func bulkUnarchive(episodes: [Episode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if episodes.count == 0 { return }

        do {
            try dbPool.write { db in
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
                    try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE uuid = ?", arguments: StatementArguments(values)!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.bulkUnarchive error: \(error)")
        }
    }

    private func save(fields: [String], values: [Any], useId: Bool = true, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                let idColumn = useId ? "id" : "uuid"
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) \(setStatement) WHERE \(idColumn) = ?", arguments: StatementArguments(values)!)
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.save fields error: \(error)")
        }
    }

    private func save(fieldName: String, value: DatabaseValueConvertible, episodeId: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE id = ?", arguments: [value, episodeId])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.save field by id error: \(error)")
        }
    }

    private func save(fieldName: String, value: DatabaseValueConvertible, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ?", arguments: [value, episodeUuid])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.save field by uuid error: \(error)")
        }
    }

    private func saveFieldIfNotModified(fieldName: String, modifiedFieldName: String, value: DatabaseValueConvertible, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        var saved = false
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ? AND \(modifiedFieldName) = 0", arguments: [value, episodeUuid])
                saved = (db.changesCount > 0)
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.saveFieldIfNotModified error: \(error)")
        }

        return saved
    }

    private func saveFieldIfNotModified(fieldName: String, modifiedFieldName: String, value: DatabaseValueConvertible, remoteModified: Int64, episodeUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Bool {
        var saved = false
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.episodeTableName) SET \(fieldName) = ? WHERE uuid = ? AND \(modifiedFieldName) < ?", arguments: [value, episodeUuid, remoteModified])
                saved = (db.changesCount > 0)
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.saveFieldIfNotModified error: \(error)")
        }

        return saved
    }

    private func updateAll(fields: [String], values: [Any], whereClause: String?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                var query = "UPDATE \(DataManager.episodeTableName) SET \(fields.joined(separator: " = ?, ")) = ?"
                if let whereClause = whereClause {
                    query += " WHERE \(whereClause)"
                }
                try db.execute(sql: query, arguments: StatementArguments(values)!)
            }
        } catch {
            FileLog.shared.addMessage("EpisodeDataManager.updateAll error: \(error)")
        }
    }

    // MARK: - Conversion

    private func createEpisodeFrom(resultSet rs: FMResultSet) -> Episode {
        Episode.from(resultSet: rs)
    }

    private func createEpisodeFrom(row: RowCursor.Element) -> Episode {
        Episode.from(row: row)
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
    func findGhostEpisodes(_ dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Episode] {
        let query = "SELECT SJEpisode.* FROM SJEpisode LEFT JOIN SJPodcast ON SJEpisode.podcastUuid = SJPodcast.uuid WHERE SJPodcast.uuid IS NULL"

        return loadMultiple(query: query, values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }
}
