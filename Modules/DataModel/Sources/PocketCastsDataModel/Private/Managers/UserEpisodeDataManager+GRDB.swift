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
        grdbQueue.read { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil
    }

    /// Find a user episode by download task ID using GRDB QueryInterface
    func findByDownloadTaskIdGRDB(downloadTaskId: String, grdbQueue: GRDBQueue) -> UserEpisode? {
        grdbQueue.read { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.downloadTaskId == downloadTaskId)
                .fetchOne(db)
        } ?? nil
    }

    /// Find a user episode by upload task ID using GRDB QueryInterface
    func findByUploadTaskIdGRDB(uploadTaskId: String, grdbQueue: GRDBQueue) -> UserEpisode? {
        grdbQueue.read { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.uploadTaskId == uploadTaskId)
                .fetchOne(db)
        } ?? nil
    }

    /// Find all user episodes sorted using GRDB QueryInterface
    func findAllGRDB(sortedBy: UploadedSort, limit: Int? = nil, grdbQueue: GRDBQueue) -> [UserEpisode] {
        grdbQueue.read { db in
            var request = UserEpisode
                .filter(UserEpisode.Columns.uploadStatus != UploadStatus.deleteFromCloudPending.rawValue)
                .filter(UserEpisode.Columns.uploadStatus != UploadStatus.deleteFromCloudAndLocalPending.rawValue)

            request = applySortOrder(request, sortedBy: sortedBy)

            if let limit = limit {
                request = request.limit(limit)
            }

            return (try? request.fetchAll(db)) ?? []
        } ?? []
    }

    /// Find all downloaded user episodes using GRDB QueryInterface
    func findAllDownloadedGRDB(sortedBy: UploadedSort, limit: Int? = nil, grdbQueue: GRDBQueue) -> [UserEpisode] {
        grdbQueue.read { db in
            var request = UserEpisode
                .filter(UserEpisode.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)

            request = applySortOrder(request, sortedBy: sortedBy)

            if let limit = limit {
                request = request.limit(limit)
            }

            return (try? request.fetchAll(db)) ?? []
        } ?? []
    }

    /// Find all user episodes with a specific upload status using GRDB QueryInterface
    func findAllWithUploadStatusGRDB(_ status: UploadStatus, grdbQueue: GRDBQueue) -> [UserEpisode] {
        grdbQueue.read { db in
            (try? UserEpisode
                .filter(UserEpisode.Columns.uploadStatus == status.rawValue)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Find unsynced user episodes using GRDB QueryInterface
    func unsyncedEpisodesGRDB(grdbQueue: GRDBQueue) -> [UserEpisode] {
        grdbQueue.read { db in
            let titleModFilter = UserEpisode.Columns.titleModified > 0
            let imageColorModFilter = UserEpisode.Columns.imageColorModified > 0
            let playingStatusModFilter = UserEpisode.Columns.playingStatusModified > 0
            let playedUpToModFilter = UserEpisode.Columns.playedUpToModified > 0
            let durationModFilter = UserEpisode.Columns.durationModified > 0
            let combinedFilter = titleModFilter || imageColorModFilter || playingStatusModFilter || playedUpToModFilter || durationModFilter

            return (try? UserEpisode
                .filter(combinedFilter)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Count downloaded user episodes using GRDB QueryInterface
    func downloadedEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        grdbQueue.read { db in
            (try? UserEpisode
                .filter(UserEpisode.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Find frame count for episode using GRDB QueryInterface
    func findFrameCountGRDB(episodeId: Int64, grdbQueue: GRDBQueue) -> Int64 {
        let frameCount: Int64? = grdbQueue.read { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.id == episodeId)
                .select(UserEpisode.Columns.cachedFrameCount)
                .fetchOne(db)
        } ?? nil

        return frameCount ?? 0
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Remove orphaned user episodes using GRDB QueryInterface
    func removeOrphanedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.uploadStatus == UploadStatus.notUploaded.rawValue)
                .filter(
                    UserEpisode.Columns.episodeStatus == DownloadStatus.notDownloaded.rawValue ||
                    UserEpisode.Columns.episodeStatus == DownloadStatus.downloadFailed.rawValue
                )
                .deleteAll(db)
        }
    }

    /// Delete user episode by UUID using GRDB QueryInterface
    func deleteGRDB(userEpisodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.uuid == userEpisodeUuid)
                .deleteAll(db)
        }
    }

    /// Delete multiple user episodes by UUIDs using GRDB QueryInterface
    func deleteGRDB(userEpisodeUuids: [String], grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(userEpisodeUuids.contains(UserEpisode.Columns.uuid))
                .deleteAll(db)
        }
    }

    /// Clear download task ID using GRDB QueryInterface
    func clearDownloadTaskIdGRDB(episode: UserEpisode, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.id == episode.id)
                .updateAll(db, UserEpisode.Columns.downloadTaskId.set(to: nil))
        }
    }

    /// Clear upload task ID using GRDB QueryInterface
    func clearUploadTaskIdGRDB(episode: UserEpisode, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.id == episode.id)
                .updateAll(db, UserEpisode.Columns.uploadTaskId.set(to: nil))
        }
    }

    /// Save frame count using GRDB QueryInterface
    func saveFrameCountGRDB(episodeId: Int64, frameCount: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UserEpisode
                .filter(UserEpisode.Columns.id == episodeId)
                .updateAll(db, UserEpisode.Columns.cachedFrameCount.set(to: frameCount))
        }
    }

    // MARK: - Helper Methods

    /// Apply sort order to a UserEpisode request
    private func applySortOrder(_ request: QueryInterfaceRequest<UserEpisode>, sortedBy: UploadedSort) -> QueryInterfaceRequest<UserEpisode> {
        switch sortedBy {
        case .newestToOldest:
            return request.order(UserEpisode.Columns.addedDate.desc)
        case .oldestToNewest:
            return request.order(UserEpisode.Columns.addedDate.asc)
        case .titleAtoZ:
            return request.order(UserEpisode.Columns.title.collating(.localizedCaseInsensitiveCompare).asc)
        case .titleZtoA:
            return request.order(UserEpisode.Columns.title.collating(.localizedCaseInsensitiveCompare).desc)
        case .shortestToLongest:
            return request.order(UserEpisode.Columns.duration.asc)
        case .longestToShortest:
            return request.order(UserEpisode.Columns.duration.desc)
        }
    }
}
