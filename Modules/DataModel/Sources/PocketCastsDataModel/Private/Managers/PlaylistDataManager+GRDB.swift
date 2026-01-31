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
            var request = EpisodeFilter.all()

            if FeatureFlag.playlistsRebranding.enabled {
                if !includeDeleted {
                    request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
                }
            } else {
                request = request.filter(EpisodeFilter.Columns.manual == false)
                if !includeDeleted {
                    request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
                }
            }

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Find playlist by UUID using GRDB QueryInterface
    func findByUuidGRDB(uuid: String, grdbQueue: GRDBQueue) -> EpisodeFilter? {
        grdbQueue.read { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.uuid == uuid)
                .fetchOne(db)
        } ?? nil
    }

    /// Get all playlists using GRDB QueryInterface
    func allPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        grdbQueue.read { db in
            var request = EpisodeFilter.all()

            if FeatureFlag.playlistsRebranding.enabled {
                if !includeDeleted {
                    request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
                }
            } else {
                request = request.filter(EpisodeFilter.Columns.manual == false)
                if !includeDeleted {
                    request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
                }
            }

            return (try? request
                .order(EpisodeFilter.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all smart playlists using GRDB QueryInterface
    func allSmartPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        grdbQueue.read { db in
            var request = EpisodeFilter
                .filter(EpisodeFilter.Columns.manual == false)

            if !includeDeleted {
                request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
            }

            return (try? request
                .order(EpisodeFilter.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all manual playlists using GRDB QueryInterface
    func allManualPlaylistsGRDB(includeDeleted: Bool, grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        grdbQueue.read { db in
            var request = EpisodeFilter
                .filter(EpisodeFilter.Columns.manual == true)

            if !includeDeleted {
                request = request.filter(EpisodeFilter.Columns.wasDeleted == false)
            }

            return (try? request
                .order(EpisodeFilter.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all unsynced playlists using GRDB QueryInterface
    func allUnsyncedPlaylistsGRDB(grdbQueue: GRDBQueue) -> [EpisodeFilter] {
        grdbQueue.read { db in
            (try? EpisodeFilter
                .filter(EpisodeFilter.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .order(EpisodeFilter.Columns.sortPosition.asc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    /// Check if playlist contains episode using GRDB QueryInterface
    func playlistContainsEpisodeGRDB(episodeUuid: String, includeDeleted: Bool, grdbQueue: GRDBQueue) -> Bool {
        let count: Int = grdbQueue.read { db in
            var request = PlaylistEpisode
                .filter(PlaylistEpisode.Columns.episodeUuid == episodeUuid)
                .filter(PlaylistEpisode.Columns.playlist_uuid != nil)

            if !includeDeleted {
                request = request.filter(PlaylistEpisode.Columns.wasDeleted == false)
            }

            return (try? request.limit(1).fetchCount(db)) ?? 0
        } ?? 0

        return count > 0
    }

    /// Get manual playlist UUIDs for an episode using GRDB QueryInterface
    func manualPlaylistUUIDsGRDB(for episodeUUID: String, grdbQueue: GRDBQueue) -> [String] {
        return grdbQueue.read { db in
            let rows = try? PlaylistEpisode
                .filter(PlaylistEpisode.Columns.episodeUuid == episodeUUID)
                .select(PlaylistEpisode.Columns.playlist_uuid, as: String?.self)
                .distinct()
                .fetchAll(db)

            return rows?.compactMap { $0 } ?? []
        } ?? []
    }

    /// Get next sort position for playlist using GRDB QueryInterface
    func nextSortPositionForPlaylistGRDB(grdbQueue: GRDBQueue) -> Int {
        let maxPosition: Int32? = grdbQueue.read { db in
            try? EpisodeFilter.select(max(EpisodeFilter.Columns.sortPosition)).fetchOne(db)
        } ?? nil

        return Int(maxPosition ?? 0) + 1
    }

    /// Get first sort position for playlist using GRDB QueryInterface
    func firstSortPositionForPlaylistGRDB(grdbQueue: GRDBQueue) -> Int {
        let minPosition: Int32? = grdbQueue.read { db in
            try? EpisodeFilter.select(min(EpisodeFilter.Columns.sortPosition)).fetchOne(db)
        } ?? nil

        return Int(minPosition ?? 0)
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete deleted playlists using GRDB QueryInterface
    func deleteDeletedPlaylistsGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.wasDeleted == true)
                .deleteAll(db)
        }
    }

    /// Mark all playlists as synced using GRDB QueryInterface
    func markAllSyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .updateAll(db, EpisodeFilter.Columns.syncStatus.set(to: SyncStatus.synced.rawValue))
        }
    }

    /// Mark all playlists as unsynced using GRDB QueryInterface
    func markAllUnsyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.syncStatus == SyncStatus.synced.rawValue)
                .updateAll(db, EpisodeFilter.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue))
        }
    }

    /// Delete a playlist using GRDB QueryInterface
    func deleteGRDB(playlist: EpisodeFilter, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.uuid == playlist.uuid)
                .deleteAll(db)

            try? PlaylistEpisode
                .filter(PlaylistEpisode.Columns.playlist_uuid == playlist.uuid || PlaylistEpisode.Columns.playlist_id == playlist.id)
                .deleteAll(db)
        }
    }

    /// Delete all episodes in a playlist using GRDB QueryInterface
    func deleteAllEpisodesGRDB(in playlist: EpisodeFilter, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            let deletedCount = try? PlaylistEpisode
                .filter(PlaylistEpisode.Columns.playlist_uuid == playlist.uuid || PlaylistEpisode.Columns.playlist_id == playlist.id)
                .deleteAll(db)

            if (deletedCount ?? 0) > 0 {
                playlist.syncStatus = SyncStatus.notSynced.rawValue
                try? EpisodeFilter
                    .filter(EpisodeFilter.Columns.uuid == playlist.uuid)
                    .updateAll(
                        db,
                        EpisodeFilter.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue),
                        EpisodeFilter.Columns.playlistUpdateDate.set(to: Date.now.timeIntervalSince1970)
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
                    UPDATE \(EpisodeFilter.databaseTableName)
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
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.uuid == playlist.uuid)
                .updateAll(
                    db,
                    EpisodeFilter.Columns.sortPosition.set(to: newPosition),
                    EpisodeFilter.Columns.syncStatus.set(to: SyncStatus.notSynced.rawValue),
                    EpisodeFilter.Columns.playlistUpdateDate.set(to: Date.now.timeIntervalSince1970)
                )
        }
    }

    /// Update playlist update date using GRDB QueryInterface
    func updatePlaylistUpdateDateGRDB(for playlist: EpisodeFilter, to date: Date, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? EpisodeFilter
                .filter(EpisodeFilter.Columns.uuid == playlist.uuid)
                .updateAll(db, EpisodeFilter.Columns.playlistUpdateDate.set(to: date.timeIntervalSince1970))
        }
    }
}
