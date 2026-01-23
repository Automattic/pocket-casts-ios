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
        let record: PodcastRecord? = grdbQueue.read { db in
            try? PodcastRecord
                .filter(PodcastRecord.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return podcastFromRecord(record)
    }

    /// Get all podcasts from database using GRDB QueryInterface
    func allPodcastsGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        let records: [PodcastRecord] = grdbQueue.read { db in
            (try? PodcastRecord
                .order(PodcastRecord.Columns.sortOrder.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { podcastFromRecord($0) }
    }

    /// Get all subscribed podcasts from database using GRDB QueryInterface
    func allSubscribedPodcastsGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        let records: [PodcastRecord] = grdbQueue.read { db in
            (try? PodcastRecord
                .filter(PodcastRecord.Columns.subscribed == 1)
                .order(PodcastRecord.Columns.sortOrder.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { podcastFromRecord($0) }
    }

    /// Get random podcasts using GRDB QueryInterface
    func randomPodcastsGRDB(limit: Int = 5, grdbQueue: GRDBQueue) -> [Podcast] {
        let records: [PodcastRecord] = grdbQueue.read { db in
            (try? PodcastRecord
                .order(sql: "RANDOM()")
                .limit(limit)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { podcastFromRecord($0) }
    }

    /// Count podcasts in a folder using GRDB QueryInterface
    func countPodcastsInFolderGRDB(folderUuid: String?, grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            var request = PodcastRecord
                .filter(PodcastRecord.Columns.subscribed == 1)

            if let folderUuid = folderUuid {
                request = request.filter(PodcastRecord.Columns.folderUuid == folderUuid)
            } else {
                request = request.filter(PodcastRecord.Columns.folderUuid == nil)
            }

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Get all unsynced podcasts using GRDB QueryInterface
    func allUnsyncedGRDB(grdbQueue: GRDBQueue) -> [Podcast] {
        let records: [PodcastRecord] = grdbQueue.read { db in
            (try? PodcastRecord
                .filter(PodcastRecord.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { podcastFromRecord($0) }
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
            try? PodcastRecord
                .filter(PodcastRecord.Columns.uuid == uuid)
                .deleteAll(db)
        }
    }

    /// Mark all podcasts as synced using GRDB QueryInterface
    func markAllSyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord.updateAll(
                db,
                PodcastRecord.Columns.syncStatus.set(to: SyncStatus.synced.rawValue)
            )
        }
    }

    /// Mark all subscribed podcasts as unsynced using GRDB QueryInterface
    func markAllUnsyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord
                .filter(PodcastRecord.Columns.subscribed == 1)
                .updateAll(db, PodcastRecord.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue))
        }
    }

    /// Remove all podcasts from folders using GRDB QueryInterface
    func removeAllPodcastsFromAllFoldersGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord.updateAll(
                db,
                PodcastRecord.Columns.folderUuid.set(to: nil)
            )
        }
    }

    /// Remove all podcasts from a specific folder using GRDB QueryInterface
    func removeAllPodcastsFromFolderGRDB(folderUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord
                .filter(PodcastRecord.Columns.folderUuid == folderUuid)
                .updateAll(
                    db,
                    PodcastRecord.Columns.folderUuid.set(to: nil),
                    PodcastRecord.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue)
                )
        }
    }

    /// Update podcast grouping for all podcasts using GRDB QueryInterface
    func updateAllPodcastGroupingGRDB(to grouping: PodcastGrouping, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord
                .filter(PodcastRecord.Columns.subscribed == 1)
                .updateAll(db, PodcastRecord.Columns.episodeGrouping.set(to: grouping.rawValue))
        }
    }

    /// Update show archived setting for all podcasts using GRDB QueryInterface
    func updateAllShowArchivedGRDB(to showArchived: Bool, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PodcastRecord
                .filter(PodcastRecord.Columns.subscribed == 1)
                .updateAll(db, PodcastRecord.Columns.showArchived.set(to: showArchived))
        }
    }

    // MARK: - Helper Methods

    /// Convert a PodcastRecord to a Podcast model object
    private func podcastFromRecord(_ record: PodcastRecord) -> Podcast {
        let podcast = Podcast()
        podcast.id = record.id ?? 0
        podcast.addedDate = record.addedDate.flatMap { DBUtils.convertDate(value: $0) }
        podcast.autoDownloadSetting = record.autoDownloadSetting
        podcast.autoAddToUpNext = record.autoAddToUpNext
        podcast.autoArchiveEpisodeLimit = record.episodeKeepSetting
        podcast.backgroundColor = record.backgroundColor
        podcast.detailColor = record.detailColor
        podcast.primaryColor = record.primaryColor
        podcast.secondaryColor = record.secondaryColor
        podcast.lastColorDownloadDate = record.lastColorDownloadDate.flatMap { DBUtils.convertDate(value: $0) }
        podcast.imageURL = record.imageURL
        podcast.latestEpisodeUuid = record.latestEpisodeUuid
        podcast.latestEpisodeDate = record.latestEpisodeDate.flatMap { DBUtils.convertDate(value: $0) }
        podcast.mediaType = record.mediaType
        podcast.lastThumbnailDownloadDate = record.lastThumbnailDownloadDate.flatMap { DBUtils.convertDate(value: $0) }
        podcast.thumbnailStatus = record.thumbnailStatus
        podcast.podcastUrl = record.podcastUrl
        podcast.author = record.author
        podcast.playbackSpeed = record.playbackSpeed
        podcast.boostVolume = record.boostVolume
        podcast.trimSilenceAmount = record.trimSilenceAmount
        podcast.podcastCategory = record.podcastCategory
        podcast.podcastDescription = record.podcastDescription
        podcast.podcastHTMLDescription = record.podcastHTMLDescription
        podcast.sortOrder = record.sortOrder
        podcast.startFrom = record.startFrom
        podcast.skipLast = record.skipLast
        podcast.subscribed = record.subscribed
        podcast.title = record.title
        podcast.uuid = record.uuid
        podcast.syncStatus = record.syncStatus
        podcast.colorVersion = record.colorVersion
        podcast.pushEnabled = record.pushEnabled
        podcast.episodeSortOrder = record.episodeSortOrder
        podcast.showType = record.showType
        podcast.estimatedNextEpisode = record.estimatedNextEpisode.flatMap { DBUtils.convertDate(value: $0) }
        podcast.episodeFrequency = record.episodeFrequency
        podcast.lastUpdatedAt = record.lastUpdatedAt
        podcast.excludeFromAutoArchive = record.excludeFromAutoArchive
        podcast.overrideGlobalEffects = record.overrideGlobalEffects
        podcast.overrideGlobalArchive = record.overrideGlobalArchive
        podcast.autoArchivePlayedAfter = record.autoArchivePlayedAfter
        podcast.autoArchiveInactiveAfter = record.autoArchiveInactiveAfter
        podcast.episodeGrouping = record.episodeGrouping
        podcast.isPaid = record.isPaid
        podcast.licensing = record.licensing
        podcast.fullSyncLastSyncAt = record.fullSyncLastSyncAt
        podcast.showArchived = record.showArchived
        podcast.refreshAvailable = record.refreshAvailable
        podcast.folderUuid = record.folderUuid
        podcast.usedCustomEffectsBefore = record.usedCustomEffectsBefore
        podcast.isPrivate = record.isPrivate
        podcast.fundingURL = record.fundingURL
        return podcast
    }
}
