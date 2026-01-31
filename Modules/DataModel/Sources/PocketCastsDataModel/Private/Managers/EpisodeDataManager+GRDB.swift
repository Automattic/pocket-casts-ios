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
        return grdbQueue.read { db in
            try? Episode
                .filter(Episode.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil
    }

    /// Find an episode by download task ID using GRDB QueryInterface
    func findByDownloadTaskIdGRDB(downloadTaskId: String, grdbQueue: GRDBQueue) -> Episode? {
        return grdbQueue.read { db in
            try? Episode
                .filter(Episode.Columns.downloadTaskId == downloadTaskId)
                .fetchOne(db)
        } ?? nil
    }

    /// Find all episodes for a podcast using GRDB QueryInterface
    func allEpisodesForPodcastGRDB(id: Int64, grdbQueue: GRDBQueue) -> [Episode] {
        return grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.podcast_id == id)
                .filter(Episode.Columns.wasDeleted == false)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Find the latest episode for a podcast using GRDB QueryInterface
    func findLatestEpisodeGRDB(podcast: Podcast, grdbQueue: GRDBQueue) -> Episode? {
        return grdbQueue.read { db in
            try? Episode
                .filter(Episode.Columns.podcast_id == podcast.id)
                .filter(Episode.Columns.wasDeleted == false)
                .order(Episode.Columns.publishedDate.desc)
                .order(Episode.Columns.addedDate.desc)
                .limit(1)
                .fetchOne(db)
        } ?? nil
    }

    /// Find latest episodes for a podcast using GRDB QueryInterface
    func findLatestEpisodesGRDB(podcast: Podcast, limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        return grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.podcast_id == podcast.id)
                .filter(Episode.Columns.wasDeleted == false)
                .order(Episode.Columns.publishedDate.desc)
                .order(Episode.Columns.addedDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Find episodes with listen history using GRDB QueryInterface
    func episodesWithListenHistoryGRDB(limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        return grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.lastPlaybackInteractionDate != nil)
                .filter(Episode.Columns.lastPlaybackInteractionDate > 0)
                .order(Episode.Columns.lastPlaybackInteractionDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Count downloaded episodes using GRDB QueryInterface
    func downloadedEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Count failed download episodes using GRDB QueryInterface
    func failedDownloadEpisodeCountGRDB(grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.episodeStatus == DownloadStatus.downloadFailed.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Check if a downloaded episode exists using GRDB QueryInterface
    func downloadedEpisodeExistsGRDB(uuid: String, grdbQueue: GRDBQueue) -> Bool {
        let count: Int = grdbQueue.read { db in
            (try? Episode
                .filter(Episode.Columns.uuid == uuid)
                .filter(Episode.Columns.episodeStatus == DownloadStatus.downloaded.rawValue)
                .fetchCount(db)) ?? 0
        } ?? 0

        return count > 0
    }

    /// Find unsynced episodes using GRDB QueryInterface
    func unsyncedEpisodesGRDB(limit: Int, grdbQueue: GRDBQueue) -> [Episode] {
        return grdbQueue.read { db in
            let playingStatusFilter = Episode.Columns.playingStatusModified > 0
            let playedUpToFilter = Episode.Columns.playedUpToModified > 0
            let durationFilter = Episode.Columns.durationModified > 0
            let keepEpisodeFilter = Episode.Columns.keepEpisodeModified > 0
            let archivedFilter = Episode.Columns.archivedModified > 0
            let combinedFilter = playingStatusFilter || playedUpToFilter || durationFilter || keepEpisodeFilter || archivedFilter

            return (try? Episode
                .filter(combinedFilter)
                .order(Episode.Columns.publishedDate.desc)
                .order(Episode.Columns.addedDate.desc)
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete an episode by UUID using GRDB QueryInterface
    func deleteGRDB(episodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode
                .filter(Episode.Columns.uuid == episodeUuid)
                .deleteAll(db)
        }
    }

    /// Delete all episodes for a podcast using GRDB QueryInterface
    func deleteAllEpisodesInPodcastGRDB(podcastId: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode
                .filter(Episode.Columns.podcast_id == podcastId)
                .deleteAll(db)
        }
    }

    /// Mark all episodes as having playback history synced using GRDB QueryInterface
    func markAllEpisodePlaybackHistorySyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode.updateAll(
                db,
                Episode.Columns.lastPlaybackInteractionSyncStatus.set(to: SyncStatus.synced.rawValue)
            )
        }
    }

    /// Clear all episode playback interactions using GRDB QueryInterface
    func clearAllEpisodePlaybackInteractionsGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode
                .filter(Episode.Columns.lastPlaybackInteractionDate > 0)
                .updateAll(db, Episode.Columns.lastPlaybackInteractionDate.set(to: nil))
        }
    }

    /// Clear episode playback interactions before a date using GRDB QueryInterface
    func clearEpisodePlaybackInteractionDatesBeforeGRDB(date: Date, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode
                .filter(Episode.Columns.lastPlaybackInteractionDate <= date.timeIntervalSince1970)
                .updateAll(db, Episode.Columns.lastPlaybackInteractionDate.set(to: nil))
        }
    }

    /// Mark all episodes as unarchived for a podcast using GRDB QueryInterface
    func markAllUnarchivedForPodcastGRDB(id: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Episode
                .filter(Episode.Columns.podcast_id == id)
                .updateAll(db, Episode.Columns.archived.set(to: false))
        }
    }
}
