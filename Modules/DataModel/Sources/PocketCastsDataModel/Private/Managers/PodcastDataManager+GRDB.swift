import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for PodcastDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main PodcastDataManager methods when the grdbQueryInterface feature flag is enabled.
extension PodcastDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Find a podcast by UUID using GRDB QueryInterface
    func findByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) -> Podcast? {
        grdbQueue.read { db in
            try? Podcast
                .filter(Podcast.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil
    }

    /// Get all podcasts from database using GRDB QueryInterface
    func allPodcastsGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        grdbQueue.read { db in
            (try? Podcast
                .order(Podcast.Columns.sortOrder.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all subscribed podcasts from database using GRDB QueryInterface
    func allSubscribedPodcastsGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        grdbQueue.read { db in
            (try? Podcast
                .filter(Podcast.Columns.subscribed == 1)
                .order(Podcast.Columns.sortOrder.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get random podcasts using GRDB QueryInterface
    func randomPodcastsGRDB(limit: Int = 5, grdbQueue: GRDBQueue) -> [Podcast] {
        grdbQueue.read { db in
            (try? Podcast
                .order(sql: "RANDOM()")
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Count podcasts in a folder using GRDB QueryInterface
    func countPodcastsInFolderGRDB(folderUuid: String?, grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            var request = Podcast
                .filter(Podcast.Columns.subscribed == 1)

            if let folderUuid = folderUuid {
                request = request.filter(Podcast.Columns.folderUuid == folderUuid)
            } else {
                request = request.filter(Podcast.Columns.folderUuid == nil)
            }

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Get all unsynced podcasts using GRDB QueryInterface
    func allUnsyncedGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        grdbQueue.read { db in
            (try? Podcast
                .filter(Podcast.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get unfinished episode counts per podcast using GRDB QueryInterface
    func unfinishedCountsGRDB(grdbQueue: GRDBQueue) -> [String: Int32] {
        var counts = [String: Int32]()

        grdbQueue.read { db in
            // Using raw SQL here since this is a complex aggregation query that would be
            // verbose to express with QueryInterface
            let sql = """
                SELECT p.uuid as uuid, count(e.id) as count
                FROM SJEpisode e, SJPodcast p
                WHERE e.podcast_id = p.id
                AND playingStatus <> \(PlayingStatus.completed.rawValue)
                AND archived = 0
                GROUP BY p.uuid
                """

            if let rows = try? Row.fetchAll(db, sql: sql) {
                for row in rows {
                    if let uuid: String = row["uuid"], let count: Int32 = row["count"] {
                        counts[uuid] = count
                    }
                }
            }
        }

        return counts
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete a podcast by UUID using GRDB QueryInterface
    func deleteByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast
                .filter(Podcast.Columns.uuid == uuid)
                .deleteAll(db)
        }
    }

    /// Mark all podcasts as synced using GRDB QueryInterface
    func markAllSyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast.updateAll(
                db,
                Podcast.Columns.syncStatus.set(to: SyncStatus.synced.rawValue)
            )
        }
    }

    /// Mark all subscribed podcasts as unsynced using GRDB QueryInterface
    func markAllUnsyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast
                .filter(Podcast.Columns.subscribed == 1)
                .updateAll(db, Podcast.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue))
        }
    }

    /// Remove all podcasts from folders using GRDB QueryInterface
    func removeAllPodcastsFromAllFoldersGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast.updateAll(
                db,
                Podcast.Columns.folderUuid.set(to: nil)
            )
        }
    }

    /// Remove all podcasts from a specific folder using GRDB QueryInterface
    func removeAllPodcastsFromFolderGRDB(folderUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast
                .filter(Podcast.Columns.folderUuid == folderUuid)
                .updateAll(
                    db,
                    Podcast.Columns.folderUuid.set(to: nil),
                    Podcast.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue)
                )
        }
    }

    /// Update podcast grouping for all podcasts using GRDB QueryInterface
    func updateAllPodcastGroupingGRDB(to grouping: PodcastGrouping, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast
                .filter(Podcast.Columns.subscribed == 1)
                .updateAll(db, Podcast.Columns.episodeGrouping.set(to: grouping.rawValue))
        }
    }

    /// Update show archived setting for all podcasts using GRDB QueryInterface
    func updateAllShowArchivedGRDB(to showArchived: Bool, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Podcast
                .filter(Podcast.Columns.subscribed == 1)
                .updateAll(db, Podcast.Columns.showArchived.set(to: showArchived))
        }
    }
}
