import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for EpisodeDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main EpisodeDataManager methods when the grdbQueryInterface feature flag is enabled.
extension EpisodeDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Find an episode by UUID using GRDB QueryInterface
    func findByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) -> Episode? {
        let record: EpisodeRecord? = grdbQueue.read { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return episodeFromRecord(record)
    }

    /// Find an episode by download task ID using GRDB QueryInterface
    func findByDownloadTaskIdGRDB(downloadTaskId: String, grdbQueue: GRDBQueue) -> Episode? {
        let record: EpisodeRecord? = grdbQueue.read { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.downloadTaskId == downloadTaskId)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return episodeFromRecord(record)
    }

    /// Find all episodes for a podcast using GRDB QueryInterface
    func allEpisodesForPodcastGRDB(id: Int64, grdbQueue: GRDBQueue) -> [Episode] {
        let records: [EpisodeRecord] = grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.podcast_id == id)
                .filter(EpisodeRecord.Columns.wasDeleted == false)
                .fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { episodeFromRecord($0) }
    }

    /// Find the latest episode for a podcast using GRDB QueryInterface
    func findLatestEpisodeGRDB(podcast: Podcast, grdbQueue: GRDBQueue) -> Episode? {
        let record: EpisodeRecord? = grdbQueue.read { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.podcast_id == podcast.id)
                .filter(EpisodeRecord.Columns.wasDeleted == false)
                .order(EpisodeRecord.Columns.publishedDate.desc)
                .order(EpisodeRecord.Columns.addedDate.desc)
                .limit(1)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return episodeFromRecord(record)
    }

    /// Find latest episodes for a podcast using GRDB QueryInterface
    func findLatestEpisodesGRDB(podcast: Podcast, limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        let records: [EpisodeRecord] = grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.podcast_id == podcast.id)
                .filter(EpisodeRecord.Columns.wasDeleted == false)
                .order(EpisodeRecord.Columns.publishedDate.desc)
                .order(EpisodeRecord.Columns.addedDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { episodeFromRecord($0) }
    }

    /// Find episodes with listen history using GRDB QueryInterface
    func episodesWithListenHistoryGRDB(limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        let records: [EpisodeRecord] = grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.lastPlaybackInteractionDate != nil)
                .filter(EpisodeRecord.Columns.lastPlaybackInteractionDate > 0)
                .order(EpisodeRecord.Columns.lastPlaybackInteractionDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { episodeFromRecord($0) }
    }

    /// Count downloaded episodes using GRDB QueryInterface
    func downloadedEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Count failed download episodes using GRDB QueryInterface
    func failedDownloadEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.episodeStatus == DownloadStatus.downloadFailed.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Check if a downloaded episode exists using GRDB QueryInterface
    func downloadedEpisodeExistsGRDB(uuid: String, grdbQueue: GRDBQueue) -> Bool {
        let count: Int = grdbQueue.read { db in
            (try? EpisodeRecord
                .filter(EpisodeRecord.Columns.uuid == uuid)
                .filter(EpisodeRecord.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0

        return count > 0
    }

    /// Find unsynced episodes using GRDB QueryInterface
    func unsyncedEpisodesGRDB(limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        let records: [EpisodeRecord] = grdbQueue.read { db in
            let playingStatusFilter = EpisodeRecord.Columns.playingStatusModified > 0
            let playedUpToFilter = EpisodeRecord.Columns.playedUpToModified > 0
            let durationFilter = EpisodeRecord.Columns.durationModified > 0
            let keepEpisodeFilter = EpisodeRecord.Columns.keepEpisodeModified > 0
            let archivedFilter = EpisodeRecord.Columns.archivedModified > 0
            let combinedFilter = playingStatusFilter || playedUpToFilter || durationFilter || keepEpisodeFilter || archivedFilter

            return (try? EpisodeRecord
                .filter(combinedFilter)
                .order(EpisodeRecord.Columns.publishedDate.desc)
                .order(EpisodeRecord.Columns.addedDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { episodeFromRecord($0) }
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete an episode by UUID using GRDB QueryInterface
    func deleteGRDB(episodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.uuid == episodeUuid)
                .deleteAll(db)
        }
    }

    /// Delete all episodes for a podcast using GRDB QueryInterface
    func deleteAllEpisodesInPodcastGRDB(podcastId: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.podcast_id == podcastId)
                .deleteAll(db)
        }
    }

    /// Mark all episodes as having playback history synced using GRDB QueryInterface
    func markAllEpisodePlaybackHistorySyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord.updateAll(
                db,
                EpisodeRecord.Columns.lastPlaybackInteractionSyncStatus.set(to: SyncStatus.synced.rawValue)
            )
        }
    }

    /// Clear all episode playback interactions using GRDB QueryInterface
    func clearAllEpisodePlaybackInteractionsGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.lastPlaybackInteractionDate > 0)
                .updateAll(db, EpisodeRecord.Columns.lastPlaybackInteractionDate.set(to: nil))
        }
    }

    /// Clear episode playback interactions before a date using GRDB QueryInterface
    func clearEpisodePlaybackInteractionDatesBeforeGRDB(date: Date, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.lastPlaybackInteractionDate <= date.timeIntervalSince1970)
                .updateAll(db, EpisodeRecord.Columns.lastPlaybackInteractionDate.set(to: nil))
        }
    }

    /// Mark all episodes as unarchived for a podcast using GRDB QueryInterface
    func markAllUnarchivedForPodcastGRDB(id: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeRecord
                .filter(EpisodeRecord.Columns.podcast_id == id)
                .updateAll(db, EpisodeRecord.Columns.archived.set(to: false))
        }
    }

    // MARK: - Helper Methods

    /// Convert an EpisodeRecord to an Episode model object
    private func episodeFromRecord(_ record: EpisodeRecord) -> Episode? {
        let episode = Episode()
        episode.id = record.id ?? 0
        episode.addedDate = record.addedDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.lastDownloadAttemptDate = record.lastDownloadAttemptDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.detailedDescription = record.detailedDescription
        episode.downloadErrorDetails = record.downloadErrorDetails
        episode.downloadTaskId = record.downloadTaskId
        episode.downloadUrl = record.downloadUrl
        episode.episodeDescription = record.episodeDescription
        episode.episodeStatus = record.episodeStatus
        episode.fileType = record.fileType
        episode.contentType = record.contentType
        episode.keepEpisode = record.keepEpisode
        episode.playedUpTo = record.playedUpTo
        episode.duration = record.duration
        episode.playingStatus = record.playingStatus
        episode.autoDownloadStatus = record.autoDownloadStatus
        episode.publishedDate = record.publishedDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.sizeInBytes = record.sizeInBytes
        episode.playingStatusModified = record.playingStatusModified
        episode.playedUpToModified = record.playedUpToModified
        episode.durationModified = record.durationModified
        episode.keepEpisodeModified = record.keepEpisodeModified
        episode.title = record.title
        episode.uuid = record.uuid
        episode.podcastUuid = record.podcastUuid
        episode.playbackErrorDetails = record.playbackErrorDetails
        episode.cachedFrameCount = record.cachedFrameCount
        episode.lastPlaybackInteractionDate = record.lastPlaybackInteractionDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.lastPlaybackInteractionSyncStatus = record.lastPlaybackInteractionSyncStatus
        episode.podcast_id = record.podcast_id
        episode.episodeNumber = record.episodeNumber
        episode.seasonNumber = record.seasonNumber
        episode.episodeType = record.episodeType
        episode.archived = record.archived
        episode.archivedModified = record.archivedModified
        episode.lastArchiveInteractionDate = record.lastArchiveInteractionDate.flatMap { DBUtils.convertDate(value: $0) }
        episode.excludeFromEpisodeLimit = record.excludeFromEpisodeLimit
        episode.starredModified = record.starredModified
        episode.deselectedChapters = record.deselectedChapters
        episode.deselectedChaptersModified = record.deselectedChaptersModified
        episode.wasDeleted = record.wasDeleted
        return episode
    }
}
