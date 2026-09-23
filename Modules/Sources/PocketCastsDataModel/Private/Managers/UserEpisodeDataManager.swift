import PocketCastsUtils
import Foundation
import GRDB

class UserEpisodeDataManager {
    // MARK: - Query

    func findBy(uuid: String, dbQueue: GRDBQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uuid = ?", values: [uuid], dbQueue: dbQueue)
    }

    func findBy(downloadTaskId: String, dbQueue: GRDBQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE downloadTaskId = ?", values: [downloadTaskId], dbQueue: dbQueue)
    }

    func findBy(uploadTaskId: String, dbQueue: GRDBQueue) -> UserEpisode? {
        loadSingle(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uploadTaskId = ?", values: [uploadTaskId], dbQueue: dbQueue)
    }

    func findAll(sortedBy: UploadedSort, limit: Int? = nil, dbQueue: GRDBQueue) -> [UserEpisode] {
        let whereClause = "WHERE uploadStatus != \(UploadStatus.deleteFromCloudPending.rawValue) AND uploadStatus != \(UploadStatus.deleteFromCloudAndLocalPending.rawValue)"
        var limitClause = ""
        if let limit {
            limitClause = " LIMIT \(limit)"
        }
        switch sortedBy {
        case .newestToOldest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY addedDate DESC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .oldestToNewest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY addedDate ASC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .titleAtoZ:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY LOWER(title) ASC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .titleZtoA:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY LOWER(title) DESC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .shortestToLongest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY duration ASC\(limitClause)", values: nil, dbQueue: dbQueue)
        case .longestToShortest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) \(whereClause) ORDER BY duration DESC\(limitClause)", values: nil, dbQueue: dbQueue)
        }
    }

    func findAllDownloaded(sortedBy: UploadedSort, limit: Int? = nil, dbQueue: GRDBQueue) -> [UserEpisode] {
        var limitClause = ""
        if let limit {
            limitClause = " LIMIT \(limit)"
        }

        switch sortedBy {
        case .newestToOldest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY addedDate DESC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .oldestToNewest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY addedDate ASC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .titleAtoZ:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY LOWER(title) ASC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .titleZtoA:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY LOWER(title) DESC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .shortestToLongest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY duration ASC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        case .longestToShortest:
            return loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE episodeStatus = ? ORDER BY duration DESC\(limitClause)", values: [DownloadStatus.downloaded.rawValue], dbQueue: dbQueue)
        }
    }

    func findAllWithUploadStatus(_ status: UploadStatus, dbQueue: GRDBQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE uploadStatus = ?", values: [status.rawValue], dbQueue: dbQueue)
    }

    func removeOrphaned(dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uploadStatus = ? AND  ( episodeStatus = ? OR episodeStatus = ? ) ", values: [UploadStatus.notUploaded.rawValue, DownloadStatus.notDownloaded.rawValue, DownloadStatus.downloadFailed.rawValue])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.removeOrphaned fieldname error: \(error)")
            }
        }
    }

    func unsyncedEpisodes(dbQueue: GRDBQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE titleModified > 0 OR imageColorModified > 0 OR playingStatusModified > 0 OR playedUpToModified > 0 OR durationModified > 0", values: nil, dbQueue: dbQueue)
    }

    func findWhereNotNull(columnName: String, dbQueue: GRDBQueue) -> [UserEpisode] {
        loadMultiple(query: "SELECT * from \(DataManager.userEpisodeTableName) WHERE \(columnName) IS NOT NULL", values: nil, dbQueue: dbQueue)
    }

    func allUpNextEpisodes(dbQueue: GRDBQueue) -> [UserEpisode] {
        let upNextTableName = DataManager.playlistEpisodeTableName
        let userEpisodeTableName = DataManager.userEpisodeTableName
        return loadMultiple(
            query: """
            SELECT \(userEpisodeTableName).*
            FROM \(upNextTableName)
            JOIN \(userEpisodeTableName)
            ON \(userEpisodeTableName).uuid = \(upNextTableName).episodeUuid
            WHERE \(upNextTableName).playlist_id = ?
            ORDER BY \(upNextTableName).episodePosition ASC
            """,
            values: [UpNextDataManager.upNextPlaylistId],
            dbQueue: dbQueue
        )
    }

    private func loadSingle(query: String, values: [Any]?, dbQueue: GRDBQueue) -> UserEpisode? {
        var episode: UserEpisode?
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)

                if resultSet.next() {
                    episode = self.createEpisodeFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.loadSingle error: \(error)")
            }
        }

        return episode
    }

    func findFrameCount(episodeId: Int64, dbQueue: GRDBQueue) -> Int64 {
        var frameCount = 0 as Int64

        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT cachedFrameCount from \(DataManager.userEpisodeTableName) WHERE id = ?", values: [episodeId])

                if resultSet.next() {
                    frameCount = resultSet.longLongInt(forColumn: "cachedFrameCount")
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.findFrameCount error: \(error)")
            }
        }

        return frameCount
    }

    private func loadMultiple(query: String, values: [Any]?, dbQueue: GRDBQueue) -> [UserEpisode] {
        var episodes = [UserEpisode]()
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)

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

    func downloadedEpisodeCount(dbQueue: GRDBQueue) -> Int {
        var count = 0
        let query = "SELECT COUNT(*) as Count from \(DataManager.userEpisodeTableName) WHERE episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery(query, values: nil)

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

    func save(episode: UserEpisode, dbQueue: GRDBQueue) {
        if episode.id == 0 {
            episode.id = DBUtils.generateUniqueId()
        }

        do {
            try dbQueue.dbPool.write { db in
                try episode.save(db)
            }
        } catch {
            FileLog.shared.addMessage("UserEpisodeDataManager.save error: \(error)")
        }
    }

    func saveEpisode(playingStatus: PlayingStatus, episode: UserEpisode, updateSyncFlag: Bool, dbQueue: GRDBQueue) {
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

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, downloadTaskId: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "sizeInBytes", "downloadTaskId"]
        let values = [episode.episodeStatus, episode.sizeInBytes, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadError: String?, downloadTaskId: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadErrorDetails = downloadError
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadErrorDetails", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadErrorDetails), DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(autoDownloadStatus: AutoDownloadStatus, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.autoDownloadStatus = autoDownloadStatus.rawValue
        save(fieldName: "autoDownloadStatus", value: episode.autoDownloadStatus, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, downloadTaskId: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.downloadTaskId = downloadTaskId

        let fields = ["episodeStatus", "downloadTaskId"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.downloadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.uploadStatus = uploadStatus.rawValue

        let fields = ["uploadStatus"]
        let values = [episode.uploadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, uploadTaskId: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.uploadStatus = uploadStatus.rawValue
        episode.downloadTaskId = uploadTaskId

        let fields = ["uploadStatus", "uploadTaskId"]
        let values = [episode.uploadStatus, DBUtils.replaceNilWithNull(value: episode.uploadTaskId), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(uploadStatus: UploadStatus, uploadError: String?, uploadTaskId: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.uploadStatus = uploadStatus.rawValue
        episode.uploadTaskId = uploadTaskId

        let fields = ["uploadStatus", "uploadTaskId"]
        let values = [episode.uploadStatus, DBUtils.replaceNilWithNull(value: episode.uploadTaskId), episode.id] as [Any]
        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(duration: Double, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.duration = duration

        save(fieldName: "duration", value: episode.duration, episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(playbackError: String?, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.playbackErrorDetails = playbackError
        save(fieldName: "playbackErrorDetails", value: DBUtils.replaceNilWithNull(value: episode.playbackErrorDetails), episodeId: episode.id, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.sizeInBytes = sizeInBytes

        let fields = ["episodeStatus", "sizeInBytes"]
        let values = [episode.episodeStatus, episode.sizeInBytes, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveEpisode(downloadStatus: DownloadStatus, lastDownloadAttemptDate: Date, autoDownloadStatus: AutoDownloadStatus, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.episodeStatus = downloadStatus.rawValue
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        episode.autoDownloadStatus = autoDownloadStatus.rawValue

        let fields = ["episodeStatus", "lastDownloadAttemptDate", "autoDownloadStatus"]
        let values = [episode.episodeStatus, DBUtils.replaceNilWithNull(value: episode.lastDownloadAttemptDate), episode.autoDownloadStatus, episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    func saveContentType(contentType: String, episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.contentType = contentType
        save(fieldName: "contentType", value: contentType, episodeId: episode.id, dbQueue: dbQueue)
    }

    func bulkSave(episodes: [UserEpisode], dbQueue: GRDBQueue) {
        do {
            try dbQueue.dbPool.write { db in
                for episode in episodes {
                    if episode.id == 0 {
                        episode.id = DBUtils.generateUniqueId()
                    }

                    try episode.save(db)
                }
            }
        } catch {
            FileLog.shared.addMessage("UserEpisodeDataManager.bulkSave error: \(error)")
        }
    }

    func bulkMarkAsPlayed(episodes: [UserEpisode], updateSyncFlag: Bool, dbQueue: GRDBQueue) {
        if episodes.isEmpty { return }

        dbQueue.write { db in
            do {
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
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkMarkAsPlayed error: \(error)")
            }
        }
    }

    func bulkMarkAsUnPlayed(episodes: [UserEpisode], updateSyncFlag: Bool, dbQueue: GRDBQueue) {
        if episodes.isEmpty { return }

        dbQueue.write { db in
            do {
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
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkMarkAsUnPlayed error: \(error)")
            }
        }
    }

    func bulkUserFileDelete(episodes: [UserEpisode], dbQueue: GRDBQueue) {
        if episodes.isEmpty { return }

        dbQueue.write { db in
            do {
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
                    try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) \(setStatement) WHERE uuid = ?", values: values)
                }
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.bulkUserFileDelete error: \(error)")
            }
        }
    }

    func clearDownloadTaskId(episode: UserEpisode, dbQueue: GRDBQueue) {
        save(fieldName: "downloadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue)
    }

    func clearUploadTaskId(episode: UserEpisode, dbQueue: GRDBQueue) {
        save(fieldName: "uploadTaskId", value: NSNull(), episodeId: episode.id, dbQueue: dbQueue)
    }

    func delete(userEpisodeUuid: String, dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uuid = ?", values: [userEpisodeUuid])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.delete error: \(error)")
            }
        }
    }

    func delete(userEpisodeUuids: [String], dbQueue: GRDBQueue) {
        guard !userEpisodeUuids.isEmpty else { return }
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.userEpisodeTableName) WHERE uuid IN (\(DataHelper.convertArrayToInString(userEpisodeUuids)))", values: nil)
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.delete many error: \(error)")
            }
        }
    }

    func saveFrameCount(episodeId: Int64, frameCount: Int64, dbQueue: GRDBQueue) {
        save(fieldName: "cachedFrameCount", value: frameCount, episodeId: episodeId, dbQueue: dbQueue)
    }

    func saveEpisode(playedUpTo: Double, episode: UserEpisode, updateSyncFlag: Bool, dbQueue: GRDBQueue) {
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

    func markEpisodeImageUploaded(episode: UserEpisode, dbQueue: GRDBQueue) {
        episode.imageModified = 0
        episode.imageUrl = nil

        let fields = ["imageModified", "imageUrl"]
        let values = [episode.imageModified, DBUtils.replaceNilWithNull(value: episode.imageUrl), episode.id] as [Any]

        save(fields: fields, values: values, dbQueue: dbQueue)
    }

    private func save(fieldName: String, value: Any, episodeId: Int64, dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.userEpisodeTableName) SET \(fieldName) = ? WHERE id = ?", values: [value, episodeId])
            } catch {
                FileLog.shared.addMessage("UserEpisodeDataManager.save fieldname error: \(error)")
            }
        }
    }

    private func save(fields: [String], values: [Any], useId: Bool = true, dbQueue: GRDBQueue) {
        dbQueue.write { db in
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

    private func createEpisodeFrom(resultSet rs: PCDBResultSet) -> UserEpisode {
        let episode = UserEpisode()
        episode.id = rs.longLongInt(forColumn: "id")
        episode.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        episode.lastDownloadAttemptDate = DBUtils.convertDate(value: rs.double(forColumn: "lastDownloadAttemptDate"))
        episode.downloadErrorDetails = rs.string(forColumn: "downloadErrorDetails")
        episode.downloadTaskId = rs.string(forColumn: "downloadTaskId")
        episode.downloadUrl = rs.string(forColumn: "downloadUrl")
        episode.episodeStatus = rs.int(forColumn: "episodeStatus")
        episode.fileType = rs.string(forColumn: "fileType")
        episode.contentType = rs.string(forColumn: "contentType")
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
}
