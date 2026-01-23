import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for PlaylistDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main PlaylistDataManager methods when the grdbQueryInterface feature flag is enabled.
extension PlaylistDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Count playlists using GRDB QueryInterface
    func countGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            var request = PlaylistRecord.all()

            if FeatureFlag.playlistsRebranding.enabled {
                if !includeDeleted {
                    request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
                }
            } else {
                request = request.filter(PlaylistRecord.Columns.manual == false)
                if !includeDeleted {
                    request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
                }
            }

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Find playlist by UUID using GRDB QueryInterface
    func findByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) -> EpisodeFilter? {
        let record: PlaylistRecord? = grdbQueue.read { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return playlistFromRecord(record)
    }

    /// Get all playlists using GRDB QueryInterface
    func allPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        let records: [PlaylistRecord] = grdbQueue.read { db in
            var request = PlaylistRecord.all()

            if FeatureFlag.playlistsRebranding.enabled {
                if !includeDeleted {
                    request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
                }
            } else {
                request = request.filter(PlaylistRecord.Columns.manual == false)
                if !includeDeleted {
                    request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
                }
            }

            return (try? request
                .order(PlaylistRecord.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { playlistFromRecord($0) }
    }

    /// Get all smart playlists using GRDB QueryInterface
    func allSmartPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        let records: [PlaylistRecord] = grdbQueue.read { db in
            var request = PlaylistRecord
                .filter(PlaylistRecord.Columns.manual == false)

            if !includeDeleted {
                request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
            }

            return (try? request
                .order(PlaylistRecord.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { playlistFromRecord($0) }
    }

    /// Get all manual playlists using GRDB QueryInterface
    func allManualPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        let records: [PlaylistRecord] = grdbQueue.read { db in
            var request = PlaylistRecord
                .filter(PlaylistRecord.Columns.manual == true)

            if !includeDeleted {
                request = request.filter(PlaylistRecord.Columns.wasDeleted == false)
            }

            return (try? request
                .order(PlaylistRecord.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { playlistFromRecord($0) }
    }

    /// Get all unsynced playlists using GRDB QueryInterface
    func allUnsyncedPlaylistsGRDB(grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        let records: [PlaylistRecord] = grdbQueue.read { db in
            (try? PlaylistRecord
                .filter(PlaylistRecord.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .order(PlaylistRecord.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { playlistFromRecord($0) }
    }

    /// Check if playlist contains episode using GRDB QueryInterface
    func playlistContainsEpisodeGRDB(episodeUuid: String, includeDeleted: Bool, grdbQueue: GRDBQueue) -> Bool {
        let count: Int = grdbQueue.read { db in
            var request = PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.episodeUuid == episodeUuid)
                .filter(PlaylistEpisodeRecord.Columns.playlist_uuid != nil)

            if !includeDeleted {
                request = request.filter(PlaylistEpisodeRecord.Columns.wasDeleted == false)
            }

            return (try? request.limit(1).fetchCount(db)) ?? 0
        } ?? 0

        return count > 0
    }

    /// Get manual playlist UUIDs for an episode using GRDB QueryInterface
    func manualPlaylistUUIDsGRDB(for episodeUUID: String, grdbQueue: GRDBQueue) -> [String] {
        return grdbQueue.read { db in
            let rows = try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.episodeUuid == episodeUUID)
                .select(PlaylistEpisodeRecord.Columns.playlist_uuid, as: String?.self)
                .distinct()
                .fetchAll(db)

            return rows?.compactMap { $0 } ?? []
        } ?? []
    }

    /// Get next sort position for playlist using GRDB QueryInterface
    func nextSortPositionForPlaylistGRDB(grdbQueue: GRDBQueue) -> Int {
        let maxPosition: Int32? = grdbQueue.read { db in
            try? PlaylistRecord.select(max(PlaylistRecord.Columns.sortPosition)).fetchOne(db)
        } ?? nil

        return Int(maxPosition ?? 0) + 1
    }

    /// Get first sort position for playlist using GRDB QueryInterface
    func firstSortPositionForPlaylistGRDB(grdbQueue: GRDBQueue) -> Int {
        let minPosition: Int32? = grdbQueue.read { db in
            try? PlaylistRecord.select(min(PlaylistRecord.Columns.sortPosition)).fetchOne(db)
        } ?? nil

        return Int(minPosition ?? 0)
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete deleted playlists using GRDB QueryInterface
    func deleteDeletedPlaylistsGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.wasDeleted == true)
                .deleteAll(db)
        }
    }

    /// Mark all playlists as synced using GRDB QueryInterface
    func markAllSyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .updateAll(db, PlaylistRecord.Columns.syncStatus.set(to: SyncStatus.synced.rawValue))
        }
    }

    /// Mark all playlists as unsynced using GRDB QueryInterface
    func markAllUnsyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.syncStatus == SyncStatus.synced.rawValue)
                .updateAll(db, PlaylistRecord.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue))
        }
    }

    /// Delete a playlist using GRDB QueryInterface
    func deleteGRDB(playlist: EpisodeFilter, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.uuid == playlist.uuid)
                .deleteAll(db)

            try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.playlist_uuid == playlist.uuid || PlaylistEpisodeRecord.Columns.playlist_id == playlist.id)
                .deleteAll(db)
        }
    }

    /// Delete all episodes in a playlist using GRDB QueryInterface
    func deleteAllEpisodesGRDB(in playlist: EpisodeFilter, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            let deletedCount = try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.playlist_uuid == playlist.uuid || PlaylistEpisodeRecord.Columns.playlist_id == playlist.id)
                .deleteAll(db)

            if (deletedCount ?? 0) > 0 {
                playlist.syncStatus = SyncStatus.notSynced.rawValue
                try? PlaylistRecord
                    .filter(PlaylistRecord.Columns.uuid == playlist.uuid)
                    .updateAll(
                        db,
                        PlaylistRecord.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue),
                        PlaylistRecord.Columns.playlistUpdateDate.set(to: Date.now.timeIntervalSince1970)
                    )
            }
        }
    }

    /// Bump sort position for all playlists using GRDB QueryInterface
    func bumpSortPositionForAllPlaylistsGRDB(adding value: Int, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            // Using raw SQL here since GRDB QueryInterface doesn't easily support
            // incrementing a column value (sortPosition = sortPosition + value)
            try? db.execute(
                sql: """
                    UPDATE \(PlaylistRecord.databaseTableName)
                    SET sortPosition = sortPosition + ?,
                        syncStatus = ?
                    WHERE wasDeleted = 0
                    """,
                arguments: [value, SyncStatus.notSynced.rawValue]
            )
        }
    }

    /// Update playlist position using GRDB QueryInterface
    func updatePositionGRDB(playlist: EpisodeFilter, newPosition: Int32, grdbQueue: GRDBQueue) {
        playlist.sortPosition = newPosition
        playlist.syncStatus = SyncStatus.notSynced.rawValue

        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.uuid == playlist.uuid)
                .updateAll(
                    db,
                    PlaylistRecord.Columns.sortPosition.set(to: newPosition),
                    PlaylistRecord.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue),
                    PlaylistRecord.Columns.playlistUpdateDate.set(to: Date.now.timeIntervalSince1970)
                )
        }
    }

    /// Update playlist update date using GRDB QueryInterface
    func updatePlaylistUpdateDateGRDB(for playlist: EpisodeFilter, to date: Date, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistRecord
                .filter(PlaylistRecord.Columns.uuid == playlist.uuid)
                .updateAll(db, PlaylistRecord.Columns.playlistUpdateDate.set(to: date.timeIntervalSince1970))
        }
    }

    // MARK: - Helper Methods

    /// Convert a PlaylistRecord to an EpisodeFilter model object
    private func playlistFromRecord(_ record: PlaylistRecord) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.id = record.id ?? 0
        playlist.autoDownloadEpisodes = record.autoDownloadEpisodes
        playlist.customIcon = record.customIcon
        playlist.filterAllPodcasts = record.filterAllPodcasts
        playlist.filterAudioVideoType = record.filterAudioVideoType
        playlist.filterDownloaded = record.filterDownloaded
        playlist.filterFinished = record.filterFinished
        playlist.filterNotDownloaded = record.filterNotDownloaded
        playlist.filterPartiallyPlayed = record.filterPartiallyPlayed
        playlist.filterStarred = record.filterStarred
        playlist.filterUnplayed = record.filterUnplayed
        playlist.filterHours = record.filterHours
        playlist.playlistName = record.playlistName
        playlist.sortPosition = record.sortPosition
        playlist.sortType = record.sortType
        playlist.uuid = record.uuid
        playlist.podcastUuids = record.podcastUuids ?? ""
        playlist.autoDownloadLimit = record.autoDownloadLimit
        playlist.syncStatus = record.syncStatus
        playlist.wasDeleted = record.wasDeleted
        playlist.filterDuration = record.filterDuration
        playlist.longerThan = record.longerThan
        playlist.shorterThan = record.shorterThan
        playlist.manual = record.manual
        playlist.showArchivedEpisodes = record.showArchivedEpisodes
        playlist.playlistUpdateDate = record.playlistUpdateDate.flatMap { DBUtils.convertDate(value: $0) }
        return playlist
    }
}
