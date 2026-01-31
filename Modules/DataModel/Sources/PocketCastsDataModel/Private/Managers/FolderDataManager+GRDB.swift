import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for FolderDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main FolderDataManager methods when the grdbQueryInterface feature flag is enabled.
extension FolderDataManager {

    // MARK: - Update Methods using GRDB QueryInterface

    /// Delete a folder by UUID using GRDB QueryInterface
    func deleteGRDB(folderUuid: String, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder
                .filter(Folder.Columns.uuid == folderUuid)
                .deleteAll(db)
        }
    }

    /// Delete all folders using GRDB QueryInterface
    func deleteAllFoldersGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder.deleteAll(db)
        }
    }

    /// Update folder color using GRDB QueryInterface
    func updateFolderColorGRDB(folderUuid: String, color: Int32, syncModified: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder
                .filter(Folder.Columns.uuid == folderUuid)
                .updateAll(
                    db,
                    Folder.Columns.color.set(to: color),
                    Folder.Columns.syncModified.set(to: syncModified)
                )
        }
    }

    /// Update folder sync modified timestamp using GRDB QueryInterface
    func updateFolderSyncModifiedGRDB(folderUuid: String, syncModified: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder
                .filter(Folder.Columns.uuid == folderUuid)
                .updateAll(db, Folder.Columns.syncModified.set(to: syncModified))
        }
    }

    /// Bulk set sync modified for multiple folders using GRDB QueryInterface
    func bulkSetSyncModifiedGRDB(_ syncModified: Int64, onFolders folderUuids: [String], grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder
                .filter(folderUuids.contains(Folder.Columns.uuid))
                .updateAll(db, Folder.Columns.syncModified.set(to: syncModified))
        }
    }

    /// Mark all folders as synced using GRDB QueryInterface
    func markAllFoldersSyncedGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder.updateAll(db, Folder.Columns.syncModified.set(to: 0))
        }
    }

    /// Mark a folder as deleted using GRDB QueryInterface
    func markFolderAsDeletedGRDB(folderUuid: String, syncModified: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder
                .filter(Folder.Columns.uuid == folderUuid)
                .updateAll(
                    db,
                    Folder.Columns.syncModified.set(to: syncModified),
                    Folder.Columns.wasDeleted.set(to: true)
                )
        }
    }

    /// Mark all folders as deleted using GRDB QueryInterface
    func markAllFolderAsDeletedGRDB(syncModified: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? Folder.updateAll(
                db,
                Folder.Columns.syncModified.set(to: syncModified),
                Folder.Columns.wasDeleted.set(to: true)
            )
        }
    }

    /// Save sort orders for folders using GRDB QueryInterface
    func saveSortOrdersGRDB(folders: [Folder], syncModified: Int64, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            for folder in folders {
                try? Folder
                    .filter(Folder.Columns.uuid == folder.uuid)
                    .updateAll(
                        db,
                        Folder.Columns.sortOrder.set(to: folder.sortOrder),
                        Folder.Columns.syncModified.set(to: syncModified)
                    )
            }
        }
    }
}
