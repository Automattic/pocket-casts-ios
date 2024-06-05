import FMDB
import GRDB
import PocketCastsUtils

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

    func setup(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func findFolder(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Folder? {
        cachedFolderQueue.sync {
            cachedFolders.first { $0.uuid == uuid }
        }
    }

    func allFolders(includeDeleted: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Folder] {
        if includeDeleted { return cachedFolders }

        return cachedFolders.filter { $0.wasDeleted == false }
    }

    func save(folder: Folder, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                if folder.uuid.isEmpty {
                    folder.uuid = UUID().uuidString.lowercased()
                }

                if cachedFolders.contains(where: { $0.uuid == folder.uuid }) {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.execute(sql: "UPDATE \(DataManager.folderTableName) SET \(setStatement) WHERE uuid = ?", arguments: StatementArguments(self.createValuesFrom(folder, includeUuidForWhere: true))!)
                } else {
                    try db.execute(sql: "INSERT INTO \(DataManager.folderTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(folder))!)
                }
            }
        } catch {
            FileLog.shared.addMessage("FolderDataManager.save error: \(error)")
        }
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func delete(folderUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "DELETE FROM \(DataManager.folderTableName) WHERE uuid = ?", values: [folderUuid], methodName: "FolderDataManager.delete", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func deleteAllFolders(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "DELETE FROM \(DataManager.folderTableName)", values: nil, methodName: "FolderDataManager.deleteAllFolders", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveSortOrders(folders: [Folder], syncModified: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                for folders in folders {
                    try db.execute(sql: "UPDATE \(DataManager.folderTableName) SET sortOrder = ?, syncModified = ? WHERE uuid = ?", arguments: [folders.sortOrder, syncModified, folders.uuid])
                }
            }
        } catch {
            FileLog.shared.addMessage("FolderDataManager.saveSortOrders error: \(error)")
        }
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateFolderColor(folderUuid: String, color: Int32, syncModified: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET color = ?, syncModified = ? WHERE uuid = ?", values: [color, syncModified, folderUuid], methodName: "FolderDataManager.updateFolderColor", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateFolderSyncModified(folderUuid: String, syncModified: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ? WHERE uuid = ?", values: [syncModified, folderUuid], methodName: "FolderDataManager.updateFolderSyncModified", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func bulkSetSyncModified(_ syncModified: Int64, onFolders folderUuids: [String], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ? WHERE uuid IN (\(DataHelper.convertArrayToInString(folderUuids)))", values: [syncModified], methodName: "FolderDataManager.bulkSetSyncModified", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func allUnsyncedFolders(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Folder] {
        var unsyncedFolders = [Folder]()
        cachedFolderQueue.sync {
            unsyncedFolders = cachedFolders.filter { $0.syncModified > 0 }
        }

        return unsyncedFolders
    }

    func markAllFoldersSynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = 0", values: nil, methodName: "FolderDataManager.markAllFoldersSynced", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    func markFolderAsDeleted(folderUuid: String, syncModified: Int64, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.folderTableName) SET syncModified = ?, wasDeleted = 1 WHERE uuid = ?", values: [syncModified, folderUuid], methodName: "FolderDataManager.markFolderAsDeleted", onQueue: dbQueue, dbPool: dbPool)
        cacheFolders(dbQueue: dbQueue, dbPool: dbPool)
    }

    private func cacheFolders(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT * from \(DataManager.folderTableName)")

                var newFolders = [Folder]()
                while let row = try rows.next() {
                    let folder = self.createFrom(row: row)
                    newFolders.append(folder)
                }

                cachedFolderQueue.sync {
                    cachedFolders = newFolders
                }
            }
        } catch {
            FileLog.shared.addMessage("FolderDataManager.cacheFolders error: \(error)")
        }
    }

    // MARK: - Conversion

    private func createFrom(resultSet rs: FMResultSet) -> Folder {
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

    private func createFrom(row: RowCursor.Element) -> Folder {
        let folder = Folder()

        folder.uuid = row["uuid"]
        folder.name = row["name"]
        folder.color = row["color"]
        folder.addedDate = row["addedDate"]
        folder.sortOrder = row["sortOrder"]
        folder.sortType = row["sortType"]
        folder.wasDeleted = row["wasDeleted"]
        folder.syncModified = row["syncModified"]

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
