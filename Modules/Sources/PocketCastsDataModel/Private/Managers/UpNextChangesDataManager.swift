import PocketCastsUtils

class UpNextChangesDataManager {
    private let columnNames = [
        "id",
        "type",
        "uuid",
        "uuids",
        "utcTime"
    ]

    // MARK: - Query

    func findReplaceAction(dbQueue: PCDBQueue) -> UpNextChanges? {
        var replaceAction: UpNextChanges?
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.upNextChangesTableName) WHERE type = ?", values: [UpNextChanges.Actions.replace.rawValue])
                defer { resultSet.close() }

                if resultSet.next() {
                    replaceAction = self.createFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("UpNextChangesDataManager.findReplaceAction error: \(error)")
            }
        }

        return replaceAction
    }

    func findUpdateActions(dbQueue: PCDBQueue) -> [UpNextChanges] {
        var allUpdateActions = [UpNextChanges]()
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.upNextChangesTableName) WHERE type != ?", values: [UpNextChanges.Actions.replace.rawValue])
                defer { resultSet.close() }

                while resultSet.next() {
                    let action = self.createFrom(resultSet: resultSet)
                    allUpdateActions.append(action)
                }
            } catch {
                FileLog.shared.addMessage("UpNextChangesDataManager.findUpdateActions error: \(error)")
            }
        }

        return allUpdateActions
    }

    // MARK: - Update

    func saveUpNextRemove(episodeUuid: String, dbQueue: PCDBQueue) {
        saveUpdate(action: UpNextChanges.Actions.remove, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveUpNextAddToTop(episodeUuid: String, dbQueue: PCDBQueue) {
        saveUpdate(action: UpNextChanges.Actions.playNext, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveUpNextAddToBottom(episodeUuid: String, dbQueue: PCDBQueue) {
        saveUpdate(action: UpNextChanges.Actions.playLast, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveUpNextAddNowPlaying(episodeUuid: String, dbQueue: PCDBQueue) {
        saveUpdate(action: UpNextChanges.Actions.playNow, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    func saveReplace(episodeList: [String], dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                // a replace literally replaces everything that came before it, so empty the table out
                try db.executeUpdate("DELETE FROM \(DataManager.upNextChangesTableName)", values: nil)

                let upNextRemove = UpNextChanges()
                upNextRemove.id = DBUtils.generateUniqueId()
                upNextRemove.type = UpNextChanges.Actions.replace.rawValue
                upNextRemove.uuids = episodeList.joined(separator: ",")
                upNextRemove.utcTime = DBUtils.currentUTCTimeInMillis()
                try db.executeUpdate("INSERT INTO \(DataManager.upNextChangesTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(upNextChanges: upNextRemove))
            } catch {
                FileLog.shared.addMessage("UpNextChangesDataManager.saveReplace error: \(error)")
            }
        }
    }

    private func saveUpdate(action: UpNextChanges.Actions, episodeUuid: String, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                // an update replaces any other update that is for the same episode, so delete any that might exist
                try db.executeUpdate("DELETE FROM \(DataManager.upNextChangesTableName) WHERE uuid = ?", values: [episodeUuid])

                let upNextRemove = UpNextChanges()
                upNextRemove.id = DBUtils.generateUniqueId()
                upNextRemove.type = action.rawValue
                upNextRemove.uuid = episodeUuid
                upNextRemove.utcTime = DBUtils.currentUTCTimeInMillis()
                try db.executeUpdate("INSERT INTO \(DataManager.upNextChangesTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(upNextChanges: upNextRemove))
            } catch {
                FileLog.shared.addMessage("UpNextChangesDataManager.saveUpdate error: \(error)")
            }
        }
    }

    // MARK: - Delete

    func deleteChangesOlderThan(utcTime: Int64, dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.upNextChangesTableName) where utcTime <= ?", values: [utcTime])
            } catch {
                FileLog.shared.addMessage("UpNextChangesDataManager.deleteChangesOlderThan error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createFrom(resultSet rs: PCDBResultSet) -> UpNextChanges {
        let changes = UpNextChanges()

        changes.id = rs.longLongInt(forColumn: "id")
        changes.type = rs.int(forColumn: "type")
        changes.uuid = rs.string(forColumn: "uuid")
        changes.uuids = rs.string(forColumn: "uuids")
        changes.utcTime = rs.longLongInt(forColumn: "utcTime")

        return changes
    }

    private func createValuesFrom(upNextChanges: UpNextChanges) -> [Any] {
        var values = [Any]()
        values.append(upNextChanges.id)
        values.append(upNextChanges.type)
        values.append(DBUtils.replaceNilWithNull(value: upNextChanges.uuid))
        values.append(DBUtils.replaceNilWithNull(value: upNextChanges.uuids))
        values.append(upNextChanges.utcTime)

        return values
    }
}
