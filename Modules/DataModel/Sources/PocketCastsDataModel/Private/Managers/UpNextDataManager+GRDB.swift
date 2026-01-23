import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for UpNextDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main UpNextDataManager methods when the grdbQueryInterface feature flag is enabled.
extension UpNextDataManager {

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete a playlist episode using GRDB QueryInterface
    func deleteGRDB(playlistEpisode: PlaylistEpisode, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.id == playlistEpisode.id)
                .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                .deleteAll(db)
        }
    }

    /// Delete all up next episodes using GRDB QueryInterface
    func deleteAllUpNextEpisodesGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                .deleteAll(db)
        }
    }

    /// Delete all up next episodes except one using GRDB QueryInterface
    func deleteAllUpNextEpisodesExceptGRDB(episodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? PlaylistEpisodeRecord
                .filter(PlaylistEpisodeRecord.Columns.episodeUuid != episodeUuid)
                .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                .deleteAll(db)
        }
    }

    /// Delete all up next episodes not in a list of UUIDs using GRDB QueryInterface
    func deleteAllUpNextEpisodesNotInGRDB(uuids: [String], grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            if uuids.isEmpty {
                try? PlaylistEpisodeRecord
                    .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                    .deleteAll(db)
            } else {
                try? PlaylistEpisodeRecord
                    .filter(!uuids.contains(PlaylistEpisodeRecord.Columns.episodeUuid))
                    .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                    .deleteAll(db)
            }
        }
    }

    /// Delete all up next episodes in a list of UUIDs using GRDB QueryInterface
    func deleteAllUpNextEpisodesInGRDB(uuids: [String], grdbQueue: GRDBQueue) {
        guard !uuids.isEmpty else { return }

        _ = grdbQueue.write { db in
            try? PlaylistEpisodeRecord
                .filter(uuids.contains(PlaylistEpisodeRecord.Columns.episodeUuid))
                .filter(PlaylistEpisodeRecord.Columns.playlist_id == Int64(UpNextDataManager.upNextPlaylistId))
                .deleteAll(db)
        }
    }
}
