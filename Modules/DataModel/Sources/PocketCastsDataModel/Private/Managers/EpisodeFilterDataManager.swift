import FMDB
import GRDB
import PocketCastsUtils

class EpisodeFilterDataManager {
    private let columnNames = [
        "id",
        "autoDownloadEpisodes",
        "customIcon",
        "filterAllPodcasts",
        "filterAudioVideoType",
        "filterDownloaded",
        "filterFinished",
        "filterNotDownloaded",
        "filterPartiallyPlayed",
        "filterStarred",
        "filterUnplayed",
        "filterHours",
        "playlistName",
        "sortPosition",
        "sortType",
        "uuid",
        "podcastUuids",
        "autoDownloadLimit",
        "syncStatus",
        "wasDeleted",
        "filterDuration",
        "longerThan",
        "shorterThan"
    ]

    func count(includeDeleted: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var count = 0
        do {
            try dbPool.read { db in
                let query = includeDeleted ? "SELECT COUNT(*) as count from \(DataManager.filtersTableName) WHERE manual = 0" : "SELECT COUNT(*) as count from \(DataManager.filtersTableName) WHERE manual = 0 AND wasDeleted = 0"
                let rows = try Row.fetchCursor(db, sql: query)

                while let row = try rows.next() {
                    count = row["count"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.count error: \(error)")
        }

        return count
    }

    func episodeCount(forFilter filter: EpisodeFilter, episodeUuidToAdd: String?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var count = 0
        do {
            try dbPool.read { db in
                let queryForFilter = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: episodeUuidToAdd, limit: 0)

                let rows = try Row.fetchCursor(db, sql: "SELECT COUNT(*) as count from SJEpisode WHERE \(queryForFilter)")

                while let row = try rows.next() {
                    count = row["count"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.episodeCount error: \(error)")
        }

        return count
    }

    func allFilters(includeDeleted: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [EpisodeFilter] {
        let query = includeDeleted ? "SELECT * from \(DataManager.filtersTableName) WHERE manual = 0 ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.filtersTableName) WHERE manual = 0 AND wasDeleted = 0 ORDER BY sortPosition ASC"

        return allFilters(query: query, values: nil, dbQueue: dbQueue, dbPool: dbPool)
    }

    func findBy(uuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> EpisodeFilter? {
        var filter: EpisodeFilter?
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT * from \(DataManager.filtersTableName) WHERE uuid = ?", arguments: [uuid])

                if let row = try rows.next() {
                    filter = self.createFilterFrom(row: row)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.findBy error: \(error)")
        }

        return filter
    }

    func deleteDeletedFilters(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.filtersTableName) WHERE wasDeleted = 1")
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.deleteDeletedFilters error: \(error)")
        }
    }

    func allUnsyncedFilters(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [EpisodeFilter] {
        allFilters(query: "SELECT * from \(DataManager.filtersTableName) WHERE syncStatus = ? ORDER BY sortPosition ASC", values: [SyncStatus.notSynced.rawValue], dbQueue: dbQueue, dbPool: dbPool)
    }

    func updatePosition(filter: EpisodeFilter, newPosition: Int32, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        filter.sortPosition = newPosition
        filter.syncStatus = SyncStatus.notSynced.rawValue
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.filtersTableName) SET sortPosition = ?, syncStatus = ? WHERE uuid = ?", arguments: [filter.sortPosition, filter.syncStatus, filter.uuid])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.updatePosition error: \(error)")
        }
    }

    func save(filter: EpisodeFilter, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                if filter.id == 0 {
                    filter.id = DBUtils.generateUniqueId()
                    try db.execute(sql: "INSERT INTO \(DataManager.filtersTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(filter: filter))!)
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.execute(sql: "UPDATE \(DataManager.filtersTableName) SET \(setStatement) WHERE uuid = ?", arguments: StatementArguments(self.createValuesFrom(filter: filter, includeUuidForWhere: true))!)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.save error: \(error)")
        }
    }

    func delete(filter: EpisodeFilter, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(DataManager.filtersTableName) WHERE uuid = ?", arguments: [filter.uuid])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.delete error: \(error)")
        }
    }

    func markAllSynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.filtersTableName) SET syncStatus = ? WHERE syncStatus = ?", arguments: [SyncStatus.synced.rawValue, SyncStatus.notSynced.rawValue])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.markAllSynced error: \(error)")
        }
    }

    func markAllUnsynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.filtersTableName) SET syncStatus = ? WHERE syncStatus = ?", arguments: [SyncStatus.notSynced.rawValue, SyncStatus.synced.rawValue])
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.markAllUnsynced error: \(error)")
        }
    }

    private func allFilters(query: String, values: [Any]?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [EpisodeFilter] {
        var allFilters = [EpisodeFilter]()
        do {
            try dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: query, arguments: StatementArguments(values ?? [])!)

                while let row = try rows.next() {
                    let filter = self.createFilterFrom(row: row)
                    allFilters.append(filter)
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.allFilters error: \(error)")
        }

        return allFilters
    }

    func nextSortPositionForFilter(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var highestPosition = 0
        do {
            try dbPool.read { db in
                let query = "SELECT MAX(sortPosition) as highestPosition from \(DataManager.filtersTableName)"

                let rows = try Row.fetchCursor(db, sql: query)

                if let row = try rows.next() {
                    highestPosition = row["highestPosition"]
                }
            }
        } catch {
            FileLog.shared.addMessage("EpisodeFilterDataManager.nextSortPositionForFilter error: \(error)")
        }

        return highestPosition + 1
    }

    // MARK: - Conversion

    private func createFilterFrom(resultSet rs: FMResultSet) -> EpisodeFilter {
        let filter = EpisodeFilter()
        filter.id = rs.longLongInt(forColumn: "id")
        filter.autoDownloadEpisodes = rs.bool(forColumn: "autoDownloadEpisodes")
        filter.customIcon = rs.int(forColumn: "customIcon")
        filter.filterAllPodcasts = rs.bool(forColumn: "filterAllPodcasts")
        filter.filterAudioVideoType = rs.int(forColumn: "filterAudioVideoType")
        filter.filterDownloaded = rs.bool(forColumn: "filterDownloaded")
        filter.filterFinished = rs.bool(forColumn: "filterFinished")
        filter.filterNotDownloaded = rs.bool(forColumn: "filterNotDownloaded")
        filter.filterPartiallyPlayed = rs.bool(forColumn: "filterPartiallyPlayed")
        filter.filterStarred = rs.bool(forColumn: "filterStarred")
        filter.filterUnplayed = rs.bool(forColumn: "filterUnplayed")
        filter.filterHours = rs.int(forColumn: "filterHours")
        filter.playlistName = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "playlistName")
        filter.sortPosition = rs.int(forColumn: "sortPosition")
        filter.sortType = rs.int(forColumn: "sortType")
        filter.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        filter.podcastUuids = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "podcastUuids")
        filter.autoDownloadLimit = rs.int(forColumn: "autoDownloadLimit")
        filter.syncStatus = rs.int(forColumn: "syncStatus")
        filter.wasDeleted = rs.bool(forColumn: "wasDeleted")
        filter.filterDuration = rs.bool(forColumn: "filterDuration")
        filter.longerThan = rs.int(forColumn: "longerThan")
        filter.shorterThan = rs.int(forColumn: "shorterThan")

        return filter
    }

    private func createFilterFrom(row: RowCursor.Element) -> EpisodeFilter {
        let filter = EpisodeFilter()
        filter.id = row["id"]
        filter.autoDownloadEpisodes = row["autoDownloadEpisodes"]
        filter.customIcon = row["customIcon"]
        filter.filterAllPodcasts = row["filterAllPodcasts"]
        filter.filterAudioVideoType = row["filterAudioVideoType"]
        filter.filterDownloaded = row["filterDownloaded"]
        filter.filterFinished = row["filterFinished"]
        filter.filterNotDownloaded = row["filterNotDownloaded"]
        filter.filterPartiallyPlayed = row["filterPartiallyPlayed"]
        filter.filterStarred = row["filterStarred"]
        filter.filterUnplayed = row["filterUnplayed"]
        filter.filterHours = row["filterHours"]
        filter.playlistName = row["playlistName"]
        filter.sortPosition = row["sortPosition"]
        filter.sortType = row["sortType"]
        filter.uuid = row["uuid"]
        filter.podcastUuids = row["podcastUuids"]
        filter.autoDownloadLimit = row["autoDownloadLimit"]
        filter.syncStatus = row["syncStatus"]
        filter.wasDeleted = row["wasDeleted"]
        filter.filterDuration = row["filterDuration"]
        filter.longerThan = row["longerThan"]
        filter.shorterThan = row["shorterThan"]

        return filter
    }

    private func createValuesFrom(filter: EpisodeFilter, includeUuidForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(filter.id)
        values.append(filter.autoDownloadEpisodes)
        values.append(filter.customIcon)
        values.append(filter.filterAllPodcasts)
        values.append(filter.filterAudioVideoType)
        values.append(filter.filterDownloaded)
        values.append(filter.filterFinished)
        values.append(filter.filterNotDownloaded)
        values.append(filter.filterPartiallyPlayed)
        values.append(filter.filterStarred)
        values.append(filter.filterUnplayed)
        values.append(filter.filterHours)
        values.append(filter.playlistName)
        values.append(filter.sortPosition)
        values.append(filter.sortType)
        values.append(filter.uuid)
        values.append(filter.podcastUuids)
        values.append(filter.autoDownloadLimit)
        values.append(filter.syncStatus)
        values.append(filter.wasDeleted)
        values.append(filter.filterDuration)
        values.append(filter.longerThan)
        values.append(filter.shorterThan)

        if includeUuidForWhere {
            values.append(filter.uuid)
        }

        return values
    }
}
