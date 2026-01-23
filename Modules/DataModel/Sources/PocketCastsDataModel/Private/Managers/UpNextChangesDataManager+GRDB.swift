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
        let record: UpNextChangesRecord? = grdbQueue.read { db in
            try? UpNextChangesRecord
                .filter(UpNextChangesRecord.Columns.type == UpNextChanges.Actions.replace.rawValue)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return upNextChangesFromRecord(record)
    }

    /// Find all update actions using GRDB QueryInterface
    func findUpdateActionsGRDB(grdbQueue: GRDBQueue) -> [UpNextChanges] {
        let records: [UpNextChangesRecord] = grdbQueue.read { db in
            (try? UpNextChangesRecord
                .filter(UpNextChangesRecord.Columns.type != UpNextChanges.Actions.replace.rawValue)
                .fetchAll(db)) ?? []
        } ?? []

        return records.map { upNextChangesFromRecord($0) }
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete changes older than a specific time using GRDB QueryInterface
    func deleteChangesOlderThanGRDB(utcTime: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChangesRecord
                .filter(UpNextChangesRecord.Columns.utcTime <= utcTime)
                .deleteAll(db)
        }
    }

    /// Delete all changes using GRDB QueryInterface
    func deleteAllChangesGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChangesRecord.deleteAll(db)
        }
    }

    /// Delete changes for a specific episode UUID using GRDB QueryInterface
    func deleteChangesForEpisodeGRDB(episodeUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? UpNextChangesRecord
                .filter(UpNextChangesRecord.Columns.uuid == episodeUuid)
                .deleteAll(db)
        }
    }

    // MARK: - Helper Methods

    /// Convert an UpNextChangesRecord to an UpNextChanges model object
    private func upNextChangesFromRecord(_ record: UpNextChangesRecord) -> UpNextChanges {
        let changes = UpNextChanges()
        changes.id = record.id ?? 0
        changes.type = record.type
        changes.uuid = record.uuid
        changes.uuids = record.uuids
        changes.utcTime = record.utcTime
        return changes
    }
}
