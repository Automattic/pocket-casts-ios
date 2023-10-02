import FMDB
import PocketCastsUtils

class UserEpisodeDataManager {
    private let columnNames = [
        "id",
        "addedDate",
        "lastDownloadAttemptDate",
        "downloadErrorDetails",
        "downloadTaskId",
        "downloadUrl",
        "episodeStatus",
        "fileType",
        "playedUpTo",
        "duration",
        "playingStatus",
        "autoDownloadStatus",
        "publishedDate",
        "sizeInBytes",
        "playingStatusModified",
        "playedUpToModified",
        "title",
        "uuid",
        "playbackErrorDetails",
        "cachedFrameCount",
        "uploadStatus",
        "uploadTaskId",
        "imageUrl",
        "imageColor",
        "hasCustomImage",
        "imageColorModified",
        "titleModified",
        "durationModified",
        "imageModified"
    ]

    // MARK: - Query

    func findBy(uuid: String, dbQueue: FMDatabaseQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uuid = ?", values: [uuid], dbQueue: dbQueue)
    }

    func findBy(downloadTaskId: String, dbQueue: FMDatabaseQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE downloadTaskId = ?", values: [downloadTaskId], dbQueue: dbQueue)
    }

    func findBy(uploadTaskId: String, dbQueue: FMDatabaseQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uploadTaskId = ?", values: [uploadTaskId], dbQueue: dbQueue)
    }

    func findAll(sortedBy: UploadedSort, limit: Int? = nil, dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        let whereClause = "WHERE uploadStatus != \(UploadStatus.deleteFromCloudPending.rawValue) AND uploadStatus != \(UploadStatus.deleteFromCloudAndLocalPending.rawValue)"
        var limitClause = ""
        if let limit = limit {
            limitClause = " LIMIT \(limit)"
        }
        switch sortedBy {
        case .newestToOldest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY addedDate DESC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .oldestToNewest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY addedDate ASC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .titleAtoZ:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY LOWER(title) ASC\(limitClause)", values: nil, dbQueue: dbQueue)
        }
    }

    func findAllDownloaded(sortedBy: UploadedSort, limit: Int? = nil, dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        var limitClause = ""
        if let limit = limit {
            limitClause = " LIMIT \(limit)"
        }

        switch sortedBy {
        case .newestToOldest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY addedDate DESC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .oldestToNewest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY addedDate ASC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .titleAtoZ:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY LOWER(title) ASC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        }
    }

    func findAllWithUploadStatus(_ status: UploadStatus, dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uploadStatus = ?", values: [status.rawValue], dbQueue: dbQueue)
    }

    func removeOrphaned(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uploadStatus = ? AND  ( episodeStatus = ? OR episodeStatus = ? ) ", values: [UploadStatus.notUploaded.rawValue, DownloadStatus.notDownloaded.rawValue, DownloadStatus.downloadFailed.rawValue])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.removeOrphaned fieldname error: \(error)")
            }
        }
    }

    func unsyncedEpisodes(dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE titleModified > 0 OR imageColorModified > 0 OR playingStatusModified > 0 OR playedUpToModified > 0 OR durationModified > 0", values: nil, dbQueue: dbQueue)
    }

    func findWhereNotNull(columnName: String, dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE \(columnName) IS NOT NULL", values: nil, dbQueue: dbQueue)
    }

    func allUpNextEpisodes(dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        let upNextTableName = DataManager.playlistEpisodeTableName
        let userEpisodeTableName = DataManager.userEpisodeTableName
        return loadMultiple(query: "SELECT \(userEpisodeTableName).* FROM \(upNextTableName) JOIN \(userEpisodeTableName) ON \(userEpisodeTableName).uuid = \(upNextTableName).episodeUuid ORDER BY \(upNextTableName).episodePosition ASC", values: nil, dbQueue: dbQueue)
    }

    func allUpNextEpisodeUuids(dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        let upNextTableName = DataManager.playlistEpisodeTableName
        let userEpisodeTableName = DataManager.userEpisodeTableName

        var episodes = [UserEpisode]()
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT \(userEpisodeTableName).uuid FROM \(upNextTableName) JOIN \(userEpisodeTableName) ON \(userEpisodeTableName).uuid = \(upNextTableName).episodeUuid ORDER BY \(upNextTableName).episodePosition ASC", values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    let episode = UserEpisode()
                    episode.uuid = DBUtils.nonNilStringFromColumn(resultSet: resultSet, columnName: "uuid")
                    episode.isStub = true
                    episodes.append(episode)
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.allUpNextEpisodeUuids error: \(error)")
            }
        }

        return episodes
    }

    private func loadSingle(query: String, values: [Any]?, dbQueue: FMDatabaseQueue) -> UserEpisode? {
        var episode: UserEpisode?
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                if resultSet.next() {
                    episode = self.createEpisodeFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.loadSingle error: \(error)")
            }
        }

        return episode
    }

    func findFrameCount(episodeId: Int64, dbQueue: FMDatabaseQueue) -> Int64 {
        var frameCount = 0 as Int64

        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT cachedFrameCount from \(DataManager.userEpisodeTableName) WHERE id = ?", values: [episodeId])
                defer { resultSet.close() }

                if resultSet.next() {
                    frameCount = resultSet.longLongInt(forColumn: "cachedFrameCount")
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.findFrameCount error: \(error)")
            }
        }

        return frameCount
    }

    private func loadMultiple(query: String, values: [Any]?, dbQueue: FMDatabaseQueue) -> [UserEpisode] {
        var episodes = [UserEpisode]()
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    let episode = self.createEpisodeFrom(resultSet: resultSet)
                    episodes.append(episode)
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.loadMultiple error: \(error)")
            }
        }

        return episodes
    }

    func downloadedEpisodeCount(dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.userEpisodeTableName) WHERE episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = Int(resultSet.int(forColumn: "Count"))
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.downloadedEpisodeCount error: \(error)")
            }
        }
        return count
    }

    // MARK: - Updates

    func save(episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                if episode.id == 0 {
                    episode.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.userEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(episode: episode))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(episode: episode, includeIdForWhere: true))
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.save error: \(error)")
            }
        }
    }

    func saveEpisodeSyncInfo(uuid: String, duration: Int?, playingStatus: Int?, playedUpTo: Int?, dbQueue: FMDatabaseQueue) {
        var fields = [String]()
        var values = [Any]()

        if let duration = duration, duration > 0 {
            fields.append("duration")
            values.append(duration)
        }

        // this field defaults to non-null 0, which is not a valid playing status so we need to handle this
        if let playingStatus = playingStatus {
            let status = PlayingStatus(rawValue: Int32(playingStatus)) ?? .notPlayed
            let actualStatus = Int(status.rawValue)
            fields.append("playingStatus")
            values.append(actualStatus)
        } else {
            fields.append("playingStatus")
            values.append(PlayingStatus.notPlayed.rawValue)
        }

        if let playedUpTo = playedUpTo, playedUpTo > 0 {
            fields.append("playedUpTo")
            values.append(playedUpTo)
        }

        values.append(uuid)

        save(fields: fields, values: values, useId: false, dbQueue: dbQueue)
    }

    func saveEpisode(playingStatus: PlayingStatus, episode: UserEpisode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
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

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, downloadTaskId: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "sizeInBytes", "downloadTaskId"]
        let values = [episode.episodeStatus, episode.sizeInBytes, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadError: String?, downloadTaskId: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadErrorDetails = downloadError
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadErrorDetails", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadErrorDetails), DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(autoDownloadStatus: AutoDownloadStatus, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.autoDownloadStatus = autoDownloadStatus.rawValue
        save(fieldName: "autoDownloadStatus", value: autoDownloadStatus, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadTaskId: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.uploadStatus = uploadStatus.rawValue

        let fields = ["uploadStatus"]
        let values = [episode.uploadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, uploadTaskId: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.uploadStatus = uploadStatus.rawValue
        episode.downloadTaskId = uploadTaskId

        let fields = ["uploadStatus", "uploadTaskId"]
        let values = [episode.uploadStatus, DBUtils.replaceNilWithNull(value: episode.uploadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, uploadError: String?, uploadTaskId: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.uploadStatus = uploadStatus.rawValue
        episode.uploadTaskId = uploadTaskId

        let fields = ["uploadStatus", "uploadTaskId"]
        let values = [episode.uploadStatus, DBUtils.replaceNilWithNull(value: episode.uploadTaskId), episode.id] as [Any]
        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(duration: Double, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.duration = duration

        save(fieldName: "duration", value: episode.duration, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(playbackError: String?, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.playbackErrorDetails = playbackError
        save(fieldName: "playbackErrorDetails", value: DBUtils.replaceNilWithNull(value: episode.playbackErrorDetails), episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes

        let fields = ["episodeStatus", "sizeInBytes"]
        let values = [episode.episodeStatus, episode.sizeInBytes, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, lastDownloadAttemptDate: Date, autoDownloadStatus: AutoDownloadStatus, episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        episode.autoDownloadStatus = autoDownloadStatus.rawValue

        let fields = ["episodeStatus", "lastDownloadAttemptDate", "autoDownloadStatus"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.lastDownloadAttemptDate), episode.autoDownloadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func bulkSave(episodes: [UserEpisode], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                db.beginTransaction()

                for episode in episodes {
                    if episode.id == 0 {
                        episode.id = DBUtils.generateUniqueId()
                        try db.executeUpdate("INSERT INTO \(DataManager.userEpisodeTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(episode: episode))
                    } else {
                        let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                        try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(episode: episode, includeIdForWhere: true))
                    }
                }

                db.commit()
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkSave error: \(error)")
            }
        }
    }

    func bulkMarkAsPlayed(episodes: [UserEpisode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
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
                    try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkMarkAsPlayed error: \(error)")
            }
        }
    }

    func bulkMarkAsUnPlayed(episodes: [UserEpisode], updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
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
                    try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
                db.commit()
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkMarkAsUnPlayed error: \(error)")
            }
        }
    }

    func bulkUserFileDelete(episodes: [UserEpisode], dbQueue: FMDatabaseQueue) {
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
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkUserFileDelete error: \(error)")
            }
        }
    }

    func clearDownloadTaskId(episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        save(fieldName: "downloadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue)
    }

    func clearUploadTaskId(episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        save(fieldName: "uploadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue)
    }

    func delete(userEpisodeUuid: String, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uuid = ?", values: [userEpisodeUuid])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.delete error: \(error)")
            }
        }
    }

    func delete(userEpisodeUuids: [String], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uuid = ?", values: userEpisodeUuids)
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.delete many error: \(error)")
            }
        }
    }

    func saveFrameCount(episodeId: Int64, frameCount: Int64, dbQueue: FMDatabaseQueue) {
        save(fieldName: "cachedFrameCount", value: frameCount, episodeId: episodeId, dbQueue: dbQueue)
    }

    func saveEpisode(playedUpTo: Double, episode: UserEpisode, updateSyncFlag: Bool, dbQueue: FMDatabaseQueue) {
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

    func markEpisodeImageUploaded(episode: UserEpisode, dbQueue: FMDatabaseQueue) {
        episode.imageModified = 0
        episode.imageUrl = nil

        let fields = ["imageModified", "imageUrl"]
        let values = [episode.imageModified, DBUtils.replaceNilWithNull(value: episode.imageUrl), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    private func save(fieldName: String, value: Any, episodeId: Int64, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) SET \(fieldName) = ? WHERE id = ?", values: [value, episodeId])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.save fieldname error: \(error)")
            }
        }
    }

    private func save(fields: [String], values: [Any], useId: Bool = true, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                let setStatement = "SET \(fields.joined(separator: " = ?, ")) = ?"
                let idColumn = useId ? "id" : "uuid"
                try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) \(setStatement) WHERE \(idColumn) = ?", values: values)
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.save fieldnames error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createEpisodeFrom(resultSet rs: FMResultSet) -> UserEpisode {
        let episode = UserEpisode()
        episode.id = rs.longLongInt(forColumn: "id")
        episode.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        episode.lastDownloadAttemptDate = DBUtils.convertDate(value: rs.double(forColumn: "lastDownloadAttemptDate"))
        episode.downloadErrorDetails = rs.string(forColumn: "downloadErrorDetails")
        episode.downloadTaskId = rs.string(forColumn: "downloadTaskId")
        episode.downloadUrl = rs.string(forColumn: "downloadUrl")
        episode.episodeStatus = rs.int(forColumn: "episodeStatus")
        episode.fileType = rs.string(forColumn: "fileType")
        episode.playedUpTo = rs.double(forColumn: "playedUpTo")
        episode.duration = rs.double(forColumn: "duration")
        episode.durationModified = rs.longLongInt(forColumn: "durationModified")
        episode.playingStatus = rs.int(forColumn: "playingStatus")
        episode.autoDownloadStatus = rs.int(forColumn: "autoDownloadStatus")
        episode.publishedDate = DBUtils.convertDate(value: rs.double(forColumn: "publishedDate"))
        episode.sizeInBytes = rs.longLongInt(forColumn: "sizeInBytes")
        episode.playingStatusModified = rs.longLongInt(forColumn: "playingStatusModified")
        episode.playedUpToModified = rs.longLongInt(forColumn: "playedUpToModified")
        episode.title = rs.string(forColumn: "title")
        episode.titleModified = rs.longLongInt(forColumn: "titleModified")
        episode.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        episode.playbackErrorDetails = rs.string(forColumn: "playbackErrorDetails")
        episode.cachedFrameCount = rs.longLongInt(forColumn: "cachedFrameCount")
        episode.uploadStatus = rs.int(forColumn: "uploadStatus")
        episode.uploadTaskId = rs.string(forColumn: "uploadTaskId")
        episode.imageUrl = rs.string(forColumn: "imageUrl")
        episode.imageModified = rs.longLongInt(forColumn: "imageModified")
        episode.imageColor = rs.int(forColumn: "imageColor")
        episode.imageColorModified = rs.longLongInt(forColumn: "imageColorModified")
        episode.hasCustomImage = rs.bool(forColumn: "hasCustomImage")
        return episode
    }

    private func createValuesFrom(episode: UserEpisode, includeIdForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(episode.id)
        values.append(DBUtils.nullIfNil(value: episode.addedDate))
        values.append(episode.lastDownloadAttemptDate ?? Date(timeIntervalSince1970: 0))
        values.append(DBUtils.nullIfNil(value: episode.downloadErrorDetails))
        values.append(DBUtils.nullIfNil(value: episode.downloadTaskId))
        values.append(DBUtils.nullIfNil(value: episode.downloadUrl))
        values.append(episode.episodeStatus)
        values.append(DBUtils.nullIfNil(value: episode.fileType))
        values.append(episode.playedUpTo)
        values.append(episode.duration)
        values.append(episode.playingStatus)
        values.append(episode.autoDownloadStatus)
        values.append(DBUtils.nullIfNil(value: episode.publishedDate))
        values.append(episode.sizeInBytes)
        values.append(episode.playingStatusModified)
        values.append(episode.playedUpToModified)
        values.append(DBUtils.nullIfNil(value: episode.title))
        values.append(episode.uuid)
        values.append(DBUtils.nullIfNil(value: episode.playbackErrorDetails))
        values.append(episode.cachedFrameCount)
        values.append(episode.uploadStatus)
        values.append(DBUtils.nullIfNil(value: episode.uploadTaskId))
        values.append(DBUtils.nullIfNil(value: episode.imageUrl))
        values.append(episode.imageColor)
        values.append(episode.hasCustomImage)
        values.append(episode.imageColorModified)
        values.append(episode.titleModified)
        values.append(episode.durationModified)
        values.append(episode.imageModified)

        if includeIdForWhere {
            values.append(episode.id)
        }

        return values
    }
}
