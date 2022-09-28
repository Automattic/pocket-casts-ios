import FMDB
import PocketCastsUtils

class UserSettingsManager {
    func loadSetting(name: String, dbQueue: FMDatabaseQueue) -> UserSetting? {
        var setting: UserSetting?
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.settingsTableName) WHERE name = ?", values: [name])
                defer { resultSet.close() }

                if resultSet.next() {
                    setting = self.createFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("UserSettingsManager.loadSetting error: \(error)")
            }
        }

        return setting
    }

    func save(setting: UserSetting, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("INSERT OR IGNORE INTO \(DataManager.settingsTableName) (name, value, modifiedTime) VALUES(?, ?, ?)", values: valuesForInsert(setting: setting))
                try db.executeUpdate("UPDATE \(DataManager.settingsTableName) SET value = ?, modifiedTime = ? WHERE name = ?", values: valuesForUpdate(setting: setting))
            } catch {
                FileLog.shared.addMessage("UserSettingsManager.save error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createFrom(resultSet rs: FMResultSet) -> UserSetting {
        let setting = UserSetting()

        setting.name = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "name")
        setting.rawValue = rs.string(forColumn: "type")
        setting.modifiedTime = rs.longLongInt(forColumn: "modifiedTime")

        return setting
    }

    private func valuesForInsert(setting: UserSetting) -> [Any] {
        var values = [Any]()
        values.append(setting.name)
        values.append(DBUtils.replaceNilWithNull(value: setting.rawValue))
        values.append(setting.modifiedTime)

        return values
    }

    private func valuesForUpdate(setting: UserSetting) -> [Any] {
        var values = [Any]()
        values.append(DBUtils.replaceNilWithNull(value: setting.rawValue))
        values.append(setting.modifiedTime)
        values.append(setting.name)

        return values
    }
}
