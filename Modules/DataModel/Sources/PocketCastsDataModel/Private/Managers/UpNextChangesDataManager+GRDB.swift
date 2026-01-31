import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for UpNextChangesDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main UpNextChangesDataManager methods when the grdbQueryInterface feature flag is enabled.
extension UpNextChangesDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Find replace action using GRDB QueryInterface
    func findReplaceActionGRDB(grdbQueue: GRDBQueue) -> UpNextChanges? {
        grdbQueue.read { db in
            try? UpNextChanges
                .filter(UpNextChanges.Columns.type == UpNextChanges.Actions.replace.rawValue)
                .fetchOne(db)
        } ?? nil
    }

    /// Find all update actions using GRDB QueryInterface
    func findUpdateActionsGRDB(grdbQueue: GRDBQueue) -> [UpNextChanges] {
        grdbQueue.read { db in
            (try? UpNextChanges
                .filter(UpNextChanges.Columns.type != UpNextChanges.Actions.replace.rawValue)
                .fetchAll(db)) ?? []
        } ?? []
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete changes older than a specific time using GRDB QueryInterface
    func deleteChangesOlderThanGRDB(utcTime: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChanges
                .filter(UpNextChanges.Columns.utcTime <= utcTime)
                .deleteAll(db)
        }
    }

    /// Delete all changes using GRDB QueryInterface
    func deleteAllChangesGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChanges.deleteAll(db)
        }
    }

    /// Delete changes for a specific episode UUID using GRDB QueryInterface
    func deleteChangesForEpisodeGRDB(episodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChanges
                .filter(UpNextChanges.Columns.uuid == episodeUuid)
                .deleteAll(db)
        }
    }
}
