import PocketCastsUtils
import Foundation

class FolderDataManager {
    private let columnNames = [
        "uuid",
        "name",
        "color",
        "addedDate",
        "sortOrder",
        "sortType",
        "wasDeleted",
        "syncModified"
    ]

    private var cachedFolders = [Folder]()
    private lazy var cachedFolderQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.FolderDataQueue")

        return queue
    }()

    func setup(dbQueue: PCDBQueue) {
        cacheFolders(dbQueue: dbQueue)
    }

    func findFolder(uuid: String, dbQueue: PCDBQueue) -> Folder? {
        cachedFolderQueue.sync {
            cachedFolders.first { $0.uuid == uuid }
        }
    }

    func allFolders(includeDeleted: Bool, dbQueue: PCDBQueue) -> [Folder] {
        if includeDeleted { return cachedFolders }

        return cachedFolders.filter { $0.wasDeleted == false }
    }

    func save(folder: Folder, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                if folder.uuid.isEmpty {
                    folder.uuid = UUID().uuidString.lowercased()
                }

                if cachedFolders.contains(where: { $0.uuid == folder.uuid }) {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.folderTableName) SET \(setStatement) WHERE uuid = ?", values: self.createValuesFrom(folder, includeUuidForWhere: true))
                } else {
                    try db.executeUpdate("INSERT INTO \(DataManager.folderTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(folder))
                }
            } catch {
                FileLog.shared.addMessage("FolderDataManager.save error: \(error)")
            }
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
        cachedFolderQueue.sync {
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
                defer { resultSet.close() }

                var newFolders = [Folder]()
                while resultSet.next() {
                    let folder = self.createFrom(resultSet: resultSet)
                    newFolders.append(folder)
                }
                cachedFolderQueue.sync {
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

    private func createValuesFrom(_ folder: Folder, includeUuidForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(folder.uuid)
        values.append(folder.name)
        values.append(folder.color)
        values.append(DBUtils.nullIfNil(value: folder.addedDate))
        values.append(folder.sortOrder)
        values.append(folder.sortType)
        values.append(folder.wasDeleted)
        values.append(folder.syncModified)

        if includeUuidForWhere {
            values.append(folder.uuid)
        }

        return values
    }
}
