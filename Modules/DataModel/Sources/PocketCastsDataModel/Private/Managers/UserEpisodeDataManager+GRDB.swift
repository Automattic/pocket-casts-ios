import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for UserEpisodeDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main UserEpisodeDataManager methods when the grdbQueryInterface feature flag is enabled.
extension UserEpisodeDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Find a user episode by UUID using GRDB QueryInterface
    func findByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) -> UserEpisode? {
        let record: UserEpisodeRecord? = grdbQueue.read { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return userEpisodeFromRecord(record)
    }

    /// Find a user episode by download task ID using GRDB QueryInterface
    func findByDownloadTaskIdGRDB(downloadTaskId: String, grdbQueue: GRDBQueue) -> UserEpisode? {
        let record: UserEpisodeRecord? = grdbQueue.read { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.downloadTaskId == downloadTaskId)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return userEpisodeFromRecord(record)
    }

    /// Find a user episode by upload task ID using GRDB QueryInterface
    func findByUploadTaskIdGRDB(uploadTaskId: String, grdbQueue: GRDBQueue) -> UserEpisode? {
        let record: UserEpisodeRecord? = grdbQueue.read { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uploadTaskId == uploadTaskId)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return userEpisodeFromRecord(record)
    }

    /// Find all user episodes sorted using GRDB QueryInterface
    func findAllGRDB(sortedBy: UploadedSort, limit: Int? = nil, grdbQueue: GRDBQueue) -> [UserEpisode] {
        let records: [UserEpisodeRecord] = grdbQueue.read { db in
            var request = UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uploadStatus != UploadStatus.deleteFromCloudPending.rawValue)
                .filter(UserEpisodeRecord.Columns.uploadStatus != UploadStatus.deleteFromCloudAndLocalPending.rawValue)

            request = applySortOrder(request, sortedBy: sortedBy)

            if let limit = limit {
                request = request.limit(limit)
            }

            return (try? request.fetchAll(db)) ?? []
        } ?? []

        return records.map { userEpisodeFromRecord($0) }
    }

    /// Find all downloaded user episodes using GRDB QueryInterface
    func findAllDownloadedGRDB(sortedBy: UploadedSort, limit: Int? = nil, grdbQueue: GRDBQueue) -> [UserEpisode] {
        let records: [UserEpisodeRecord] = grdbQueue.read { db in
            var request = UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)

            request = applySortOrder(request, sortedBy: sortedBy)

            if let limit = limit {
                request = request.limit(limit)
            }

            return (try? request.fetchAll(db)) ?? []
        } ?? []

        return records.map { userEpisodeFromRecord($0) }
    }

    /// Find all user episodes with a specific upload status using GRDB QueryInterface
    func findAllWithUploadStatusGRDB(_ status: UploadStatus, grdbQueue: GRDBQueue) -> [UserEpisode] {
        let records: [UserEpisodeRecord] = grdbQueue.read { db in
            (try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uploadStatus == status.rawValue)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { userEpisodeFromRecord($0) }
    }

    /// Find unsynced user episodes using GRDB QueryInterface
    func unsyncedEpisodesGRDB(grdbQueue: GRDBQueue) -> [UserEpisode] {
        let records: [UserEpisodeRecord] = grdbQueue.read { db in
            let titleModFilter = UserEpisodeRecord.Columns.titleModified > 0
            let imageColorModFilter = UserEpisodeRecord.Columns.imageColorModified > 0
            let playingStatusModFilter = UserEpisodeRecord.Columns.playingStatusModified > 0
            let playedUpToModFilter = UserEpisodeRecord.Columns.playedUpToModified > 0
            let durationModFilter = UserEpisodeRecord.Columns.durationModified > 0
            let combinedFilter = titleModFilter || imageColorModFilter || playingStatusModFilter || playedUpToModFilter || durationModFilter

            return (try? UserEpisodeRecord
                .filter(combinedFilter)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { userEpisodeFromRecord($0) }
    }

    /// Count downloaded user episodes using GRDB QueryInterface
    func downloadedEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            (try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Find frame count for episode using GRDB QueryInterface
    func findFrameCountGRDB(episodeId: Int64, grdbQueue: GRDBQueue) -> Int64 {
        let frameCount: Int64? = grdbQueue.read { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.id == episodeId)
                .select(UserEpisodeRecord.Columns.cachedFrameCount)
                .fetchOne(db)
        } ?? nil

        return frameCount ?? 0
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Remove orphaned user episodes using GRDB QueryInterface
    func removeOrphanedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uploadStatus == UploadStatus.notUploaded.rawValue)
                .filter(
                    UserEpisodeRecord.Columns.episodeStatus == DownloadStatus.notDownloaded.rawValue ||
                    UserEpisodeRecord.Columns.episodeStatus == DownloadStatus.downloadFailed.rawValue
                )
                .deleteAll(db)
        }
    }

    /// Delete user episode by UUID using GRDB QueryInterface
    func deleteGRDB(userEpisodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.uuid == userEpisodeUuid)
                .deleteAll(db)
        }
    }

    /// Delete multiple user episodes by UUIDs using GRDB QueryInterface
    func deleteGRDB(userEpisodeUuids: [String], grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(userEpisodeUuids.contains(UserEpisodeRecord.Columns.uuid))
                .deleteAll(db)
        }
    }

    /// Clear download task ID using GRDB QueryInterface
    func clearDownloadTaskIdGRDB(episode: UserEpisode, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.id == episode.id)
                .updateAll(db, UserEpisodeRecord.Columns.downloadTaskId.set(to: nil))
        }
    }

    /// Clear upload task ID using GRDB QueryInterface
    func clearUploadTaskIdGRDB(episode: UserEpisode, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.id == episode.id)
                .updateAll(db, UserEpisodeRecord.Columns.uploadTaskId.set(to: nil))
        }
    }

    /// Save frame count using GRDB QueryInterface
    func saveFrameCountGRDB(episodeId: Int64, frameCount: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisodeRecord
                .filter(UserEpisodeRecord.Columns.id == episodeId)
                .updateAll(db, UserEpisodeRecord.Columns.cachedFrameCount.set(to: frameCount))
        }
    }

    // MARK: - Helper Methods

    /// Apply sort order to a UserEpisodeRecord request
    private func applySortOrder(_ request: QueryInterfaceRequest<UserEpisodeRecord>, sortedBy: UploadedSort) -> QueryInterfaceRequest<UserEpisodeRecord> {
        switch sortedBy {
        case .newestToOldest:
            return request.order(UserEpisodeRecord.Columns.addedDate.desc)
        case .oldestToNewest:
            return request.order(UserEpisodeRecord.Columns.addedDate.asc)
        case .titleAtoZ:
            return request.order(UserEpisodeRecord.Columns.title.collating(.localizedCaseInsensitiveCompare).asc)
        case .titleZtoA:
            return request.order(UserEpisodeRecord.Columns.title.collating(.localizedCaseInsensitiveCompare).desc)
        case .shortestToLongest:
            return request.order(UserEpisodeRecord.Columns.duration.asc)
        case .longestToShortest:
            return request.order(UserEpisodeRecord.Columns.duration.desc)
        }
    }

    /// Convert a UserEpisodeRecord to a UserEpisode model object
    private func userEpisodeFromRecord(_ record: UserEpisodeRecord) -> UserEpisode {
        let episode = UserEpisode()
        episode.id = record.id ?? 0
        episode.addedDate = record.addedDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.lastDownloadAttemptDate = record.lastDownloadAttemptDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.downloadErrorDetails = record.downloadErrorDetails
        episode.downloadTaskId = record.downloadTaskId
        episode.downloadUrl = record.downloadUrl
        episode.episodeStatus = record.episodeStatus
        episode.fileType = record.fileType
        episode.contentType = record.contentType
        episode.playedUpTo = record.playedUpTo
        episode.duration = record.duration
        episode.playingStatus = record.playingStatus
        episode.autoDownloadStatus = record.autoDownloadStatus
        episode.publishedDate = record.publishedDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.sizeInBytes = record.sizeInBytes
        episode.playingStatusModified = record.playingStatusModified
        episode.playedUpToModified = record.playedUpToModified
        episode.title = record.title
        episode.uuid = record.uuid
        episode.playbackErrorDetails = record.playbackErrorDetails
        episode.cachedFrameCount = record.cachedFrameCount
        episode.uploadStatus = record.uploadStatus
        episode.uploadTaskId = record.uploadTaskId
        episode.imageUrl = record.imageUrl
        episode.imageColor = record.imageColor
        episode.imageColorModified = record.imageColorModified
        episode.titleModified = record.titleModified
        episode.imageModified = record.imageModified
        episode.durationModified = record.durationModified
        episode.hasCustomImage = record.hasCustomImage
        return episode
    }
}
