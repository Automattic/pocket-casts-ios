import FMDB
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

    func count(includeDeleted: Bool, dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        dbQueue.inDatabase { db in
            do {
                let query = includeDeleted ? "SELECT COUNT(*) from \(DataManager.filtersTableName) WHERE manual = 0" : "SELECT COUNT(*) from \(DataManager.filtersTableName) WHERE manual = 0 AND wasDeleted = 0"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.count error: \(error)")
            }
        }

        return count
    }

    func episodeCount(forFilter filter: EpisodeFilter, episodeUuidToAdd: String?, dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        dbQueue.inDatabase { db in
            do {
                let queryForFilter = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: episodeUuidToAdd, limit: 0)
                let resultSet = try db.executeQuery("SELECT COUNT(*) from SJEpisode WHERE \(queryForFilter)", values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.episodeCount error: \(error)")
            }
        }

        return count
    }

    func allFilters(includeDeleted: Bool, dbQueue: FMDatabaseQueue) -> [EpisodeFilter] {
        let query = includeDeleted ? "SELECT * from \(DataManager.filtersTableName) WHERE manual = 0 ORDER BY sortPosition ASC" : "SELECT * from \(DataManager.filtersTableName) WHERE manual = 0 AND wasDeleted = 0 ORDER BY sortPosition ASC"

        return allFilters(query: query, values: nil, dbQueue: dbQueue)
    }

    func findBy(uuid: String, dbQueue: FMDatabaseQueue) -> EpisodeFilter? {
        var filter: EpisodeFilter?
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.filtersTableName) WHERE uuid = ?", values: [uuid])
                defer { resultSet.close() }

                if resultSet.next() {
                    filter = self.createFilterFrom(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.findBy error: \(error)")
            }
        }

        return filter
    }

    func deleteDeletedFilters(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.filtersTableName) WHERE wasDeleted = 1", values: nil)
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.deleteDeletedFilters error: \(error)")
            }
        }
    }

    func allUnsyncedFilters(dbQueue: FMDatabaseQueue) -> [EpisodeFilter] {
        allFilters(query: "SELECT * from \(DataManager.filtersTableName) WHERE syncStatus = ? ORDER BY sortPosition ASC", values: [SyncStatus.notSynced.rawValue], dbQueue: dbQueue)
    }

    func updatePosition(filter: EpisodeFilter, newPosition: Int32, dbQueue: FMDatabaseQueue) {
        filter.sortPosition = newPosition
        filter.syncStatus = SyncStatus.notSynced.rawValue
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.filtersTableName) SET sortPosition = ?, syncStatus = ? WHERE uuid = ?", values: [filter.sortPosition, filter.syncStatus, filter.uuid])
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.updatePosition error: \(error)")
            }
        }
    }

    func save(filter: EpisodeFilter, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                if filter.id == 0 {
                    filter.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.filtersTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(filter: filter))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.filtersTableName) SET \(setStatement) WHERE uuid = ?", values: self.createValuesFrom(filter: filter, includeUuidForWhere: true))
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.save error: \(error)")
            }
        }
    }

    func delete(filter: EpisodeFilter, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM \(DataManager.filtersTableName) WHERE uuid = ?", values: [filter.uuid])
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.delete error: \(error)")
            }
        }
    }

    func markAllSynced(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.filtersTableName) SET syncStatus = ? WHERE syncStatus = ?", values: [SyncStatus.synced.rawValue, SyncStatus.notSynced.rawValue])
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.markAllSynced error: \(error)")
            }
        }
    }

    func markAllUnsynced(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("UPDATE \(DataManager.filtersTableName) SET syncStatus = ? WHERE syncStatus = ?", values: [SyncStatus.notSynced.rawValue, SyncStatus.synced.rawValue])
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.markAllUnsynced error: \(error)")
            }
        }
    }

    private func allFilters(query: String, values: [Any]?, dbQueue: FMDatabaseQueue) -> [EpisodeFilter] {
        var allFilters = [EpisodeFilter]()
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    let filter = self.createFilterFrom(resultSet: resultSet)
                    allFilters.append(filter)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.allFilters error: \(error)")
            }
        }

        return allFilters
    }

    func nextSortPositionForFilter(dbQueue: FMDatabaseQueue) -> Int {
        var highestPosition = 0
        dbQueue.inDatabase { db in
            do {
                let query = "SELECT MAX(sortPosition) from \(DataManager.filtersTableName)"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    highestPosition = resultSet.long(forColumnIndex: 0)
                }
            } catch {
                FileLog.shared.addMessage("EpisodeFilterDataManager.nextSortPositionForFilter error: \(error)")
            }
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
