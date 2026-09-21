import PocketCastsUtils
import Foundation
import GRDB

class FolderDataManager {
    private let cachedFolders = Mutex([Folder]())

    func setup(dbQueue: PCDBQueue) {
        cacheFolders(dbQueue: dbQueue)
    }

    func findFolder(uuid: String, dbQueue: PCDBQueue) -> Folder? {
        cachedFolders.withLock { cachedFolders in
            cachedFolders.first { $0.uuid == uuid }
        }
    }

    func allFolders(includeDeleted: Bool, dbQueue: PCDBQueue) -> [Folder] {
        cachedFolders.withLock { cachedFolders in
            if includeDeleted { return cachedFolders }

            return cachedFolders.filter { $0.wasDeleted == false }
        }
    }

    func save(folder: Folder, dbQueue: PCDBQueue) {
        if folder.uuid.isEmpty {
            folder.uuid = UUID().uuidString.lowercased()
        }

        do {
            try (dbQueue as? GRDBQueue)?.dbPool.write { db in
                try folder.save(db)
            }
        } catch {
            FileLog.shared.addMessage("FolderDataManager.save error: \(error)")
        }
        cacheFolders(dbQueue: dbQueue)
    }

    func delete(folderUuid: String, dbQueue: PCDBQueue) {
        DataHelper.run(query: "DELETE FROM \(DataManager.folderTableName) WHERE uuid = ?", values: [folderUuid], methodName: "FolderDataManager.delete", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func deleteAllFolders(dbQueue: PCDBQueue) {
        DataHelper.run(query: "DELETE FROM \(DataManager.folderTableName)", values: nil, methodName: "FolderDataManager.deleteAllFolders", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func saveSortOrders(folders: [Folder], syncModified: Int64, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                for folders in folders {
                    try db.executeUpdate("UPDATE \(DataManager.folderTableName) SET sortOrder = ?, syncModified = ? WHERE uuid = ?", values: [folders.sortOrder, syncModified, folders.uuid])
                }
            } catch {
                FileLog.shared.addMessage("FolderDataManager.saveSortOrders error: \(error)")
            }
        }
        cacheFolders(dbQueue: dbQueue)
    }

    func updateFolderColor(folderUuid: String, color: Int32, syncModified: Int64, dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET color = ?, syncModified = ? WHERE uuid = ?", values: [color, syncModified, folderUuid], methodName: "FolderDataManager.updateFolderColor", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func updateFolderSyncModified(folderUuid: String, syncModified: Int64, dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ? WHERE uuid = ?", values: [syncModified, folderUuid], methodName: "FolderDataManager.updateFolderSyncModified", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func bulkSetSyncModified(_ syncModified: Int64, onFolders folderUuids: [String], dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ? WHERE uuid IN (\(DataHelper.convertArrayToInString(folderUuids)))", values: [syncModified], methodName: "FolderDataManager.bulkSetSyncModified", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func allUnsyncedFolders(dbQueue: PCDBQueue) -> [Folder] {
        var unsyncedFolders = [Folder]()
        cachedFolders.withLock { cachedFolders in
            unsyncedFolders = cachedFolders.filter { $0.syncModified > 0 }
        }

        return unsyncedFolders
    }

    func markAllFoldersSynced(dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = 0", values: nil, methodName: "FolderDataManager.markAllFoldersSynced", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func markFolderAsDeleted(folderUuid: String, syncModified: Int64, dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ?, wasDeleted = 1 WHERE uuid = ?", values: [syncModified, folderUuid], methodName: "FolderDataManager.markFolderAsDeleted", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    func markAllFolderAsDeleted(syncModified: Int64, dbQueue: PCDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ?, wasDeleted = 1", values: [syncModified], methodName: "FolderDataManager.markAllFolderAsDeleted", onQueue: dbQueue)
        cacheFolders(dbQueue: dbQueue)
    }

    private func cacheFolders(dbQueue: PCDBQueue) {
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.folderTableName)", values: nil)

                var newFolders = [Folder]()
                while resultSet.next() {
                    let folder = self.createFrom(resultSet: resultSet)
                    newFolders.append(folder)
                }
                cachedFolders.withLock { cachedFolders in
                    cachedFolders = newFolders
                }
            } catch {
                FileLog.shared.addMessage("FolderDataManager.cacheFolders error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createFrom(resultSet rs: PCDBResultSet) -> Folder {
        let folder = Folder()

        folder.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        folder.name = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "name")
        folder.color = rs.int(forColumn: "color")
        folder.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        folder.sortOrder = rs.int(forColumn: "sortOrder")
        folder.sortType = rs.int(forColumn: "sortType")
        folder.wasDeleted = rs.bool(forColumn: "wasDeleted")
        folder.syncModified = rs.longLongInt(forColumn: "syncModified")

        return folder
    }
}
