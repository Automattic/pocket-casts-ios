import FMDB
import PocketCastsUtils

class PodcastDataManager {
    private var cachedPodcasts = [Podcast]()
    private lazy var cachedPodcastsQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.PodcastDataQueue")

        return queue
    }()

    private let columnNames = [
        "id",
        "addedDate",
        "autoDownloadSetting",
        "autoAddToUpNext",
        "episodeKeepSetting",
        "backgroundColor",
        "detailColor",
        "primaryColor",
        "secondaryColor",
        "lastColorDownloadDate",
        "imageURL",
        "latestEpisodeUuid",
        "latestEpisodeDate",
        "mediaType",
        "lastThumbnailDownloadDate",
        "thumbnailStatus",
        "podcastUrl",
        "author",
        "playbackSpeed",
        "boostVolume",
        "trimSilenceAmount",
        "podcastCategory",
        "podcastDescription",
        "sortOrder",
        "startFrom",
        "skipLast",
        "subscribed",
        "title",
        "uuid",
        "syncStatus",
        "colorVersion",
        "pushEnabled",
        "episodeSortOrder",
        "showType",
        "estimatedNextEpisode",
        "episodeFrequency",
        "lastUpdatedAt",
        "excludeFromAutoArchive",
        "overrideGlobalEffects",
        "overrideGlobalArchive",
        "autoArchivePlayedAfter",
        "autoArchiveInactiveAfter",
        "episodeGrouping",
        "isPaid",
        "licensing",
        "fullSyncLastSyncAt",
        "showArchived",
        "refreshAvailable",
        "folderUuid"
    ]

    func setup(dbQueue: FMDatabaseQueue) {
        cachePodcasts(dbQueue: dbQueue)
    }

    // MARK: - Queries

    func allPodcasts(includeUnsubscribed: Bool, reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if !podcast.isSubscribed(), !includeUnsubscribed { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts
    }

    func allPodcastsOrderedByAddedDate(reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            addedDateSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByTitle(reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            titleSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: Bool, inFolderUuid: String? = nil, dbQueue: FMDatabaseQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        dbQueue.inDatabase { db in
            do {
                var values: [Any]?
                var whereClause = "WHERE p.subscribed = 1"
                if let inFolderUuid = inFolderUuid {
                    whereClause += " AND p.folderUuid = ?"
                    values = [inFolderUuid]
                }
                let query = "SELECT DISTINCT p.id, p.* FROM \(DataManager.podcastTableName) p LEFT JOIN \(DataManager.episodeTableName) e ON p.id = e.podcast_id AND e.id = (SELECT e.id FROM \(DataManager.episodeTableName) e WHERE e.podcast_id = p.id AND e.playingStatus != 3 AND e.archived = 0 ORDER BY e.publishedDate DESC LIMIT 1) \(whereClause) ORDER BY CASE WHEN e.publishedDate IS NULL THEN 1 ELSE 0 END, e.publishedDate DESC, p.latestEpisodeDate DESC"
                let resultSet = try db.executeQuery(query, values: values)
                defer { resultSet.close() }

                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    allPodcasts.append(podcast)
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.allPodcastsOrderedByNewestEpisodes error: \(error)")
            }
        }

        return allPodcasts
    }

    /// Returns 5 random podcasts from the DB
    /// This is here for development purposes.
    func randomPodcasts(dbQueue: FMDatabaseQueue) -> [Podcast] {
        var allPodcasts = [Podcast]()
        dbQueue.inDatabase { db in
            do {
                let query = "SELECT * FROM SJPodcast ORDER BY RANDOM() LIMIT 5"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    allPodcasts.append(podcast)
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.randomPodcasts error: \(error)")
            }
        }

        return allPodcasts
    }

    func allUnsubscribedPodcastUuids(dbQueue: FMDatabaseQueue) -> [String] {
        var allUnsubscribed = [String]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast.uuid)
            }
        }

        return allUnsubscribed
    }

    func allUnsubscribedPodcasts(dbQueue: FMDatabaseQueue) -> [Podcast] {
        var allUnsubscribed = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast)
            }
        }

        return allUnsubscribed
    }

    func allPodcastsInFolder(folder: Folder, dbQueue: FMDatabaseQueue) -> [Podcast] {
        let sortOrder = folder.folderSort()

        // newest episode release date is a special case we handle at the database level
        if sortOrder == .episodeDateNewestToOldest {
            return allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: false, inFolderUuid: folder.uuid, dbQueue: dbQueue)
        }

        // the other 3 cases we do in memory
        var allPodcastsInFolder: [Podcast] = []
        cachedPodcastsQueue.sync {
            allPodcastsInFolder = cachedPodcasts.filter { $0.isSubscribed() && $0.folderUuid == folder.uuid }
        }

        allPodcastsInFolder.sort { podcast1, podcast2 in
            if sortOrder == .dateAddedNewestToOldest {
                return addedDateSort(p1: podcast1, p2: podcast2)
            } else if sortOrder == .titleAtoZ {
                return titleSort(p1: podcast1, p2: podcast2)
            }

            return podcast1.sortOrder < podcast2.sortOrder
        }

        return allPodcastsInFolder
    }

    func countOfPodcastsInFolder(folder: Folder?, dbQueue: FMDatabaseQueue) -> Int {
        cachedPodcastsQueue.sync {
            cachedPodcasts.filter { $0.isSubscribed() && $0.folderUuid == folder?.uuid }.count
        }
    }

    func allPaidPodcasts(dbQueue: FMDatabaseQueue) -> [Podcast] {
        var allPaid = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if !podcast.isPaid { continue }

                allPaid.append(podcast)
            }
        }

        return allPaid
    }

    func allUnsynced(dbQueue: FMDatabaseQueue) -> [Podcast] {
        var unsyncedPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if podcast.syncStatus == SyncStatus.notSynced.rawValue {
                    unsyncedPodcasts.append(podcast)
                }
            }
        }

        return unsyncedPodcasts
    }

    func allOverrideGlobalArchivePodcasts(dbQueue: FMDatabaseQueue) -> [Podcast] {
        var podcastsOverrideArchive = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if podcast.isSubscribed(), podcast.overrideGlobalArchive {
                    podcastsOverrideArchive.append(podcast)
                }
            }
        }

        return podcastsOverrideArchive
    }

    func find(uuid: String, includeUnsubscribed: Bool, dbQueue: FMDatabaseQueue) -> Podcast? {
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if podcast.uuid == uuid {
                    if !includeUnsubscribed, !podcast.isSubscribed() { return nil }

                    return podcast
                }
            }

            return nil
        }
    }

    func count(dbQueue: FMDatabaseQueue) -> Int {
        var count = 0
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts {
                if !podcast.isSubscribed() { continue }

                count += 1
            }
        }

        return count
    }

    func unfinishedCounts(dbQueue: FMDatabaseQueue) -> [String: Int32] {
        var counts = [String: Int32]()
        dbQueue.inDatabase { db in
            do {
                let query = "SELECT p.uuid as uuid, count(e.id) as count FROM \(DataManager.episodeTableName) e, \(DataManager.podcastTableName) p WHERE e.podcast_id = p.id AND playingStatus <> \(PlayingStatus.completed.rawValue) AND archived = 0 GROUP BY p.uuid"
                let rs = try db.executeQuery(query, values: nil)
                defer { rs.close() }

                while rs.next() {
                    guard let uuid = rs.string(forColumn: "uuid") else { continue }
                    let count = rs.int(forColumn: "count")

                    counts[uuid] = count
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.unfinishedCounts error: \(error)")
            }
        }

        return counts
    }

    // MARK: - Updates

    func save(podcast: Podcast, dbQueue: FMDatabaseQueue) {
        // Get the existing podcast to compare if folder is being changed
        let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcast.uuid)

        dbQueue.inDatabase { db in
            do {
                if podcast.id == 0 {
                    podcast.id = DBUtils.generateUniqueId()
                    try db.executeUpdate("INSERT INTO \(DataManager.podcastTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", values: self.createValuesFrom(podcast: podcast))
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET \(setStatement) WHERE id = ?", values: self.createValuesFrom(podcast: podcast, includeIdForWhere: true))

                    // If changing folder, log it
                    if podcast.folderUuid != existingPodcast?.folderUuid {
                        FileLog.shared.foldersIssue("PodcastDataManager: update \(podcast.title ?? "") folder from \(existingPodcast?.folderUuid ?? "nil") to \(podcast.folderUuid ?? "nil")")
                    }
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.save error: \(error)")
            }
        }
        cachePodcasts(dbQueue: dbQueue)
    }

    func bulkSetFolderUuid(folderUuid: String, podcastUuids: [String], dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                // clear out any that shouldn't be in this folder
                try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", values: [folderUuid])

                // then set all the ones that should
                if podcastUuids.count > 0 {
                    try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid IN (\(DataHelper.convertArrayToInString(podcastUuids)))", values: [folderUuid])
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.bulkSetFolderUuid error: \(error)")
            }
        }
        cachePodcasts(dbQueue: dbQueue)
    }

    func updatePodcastFolder(podcastUuid: String, sortOrder: Int32, folderUuid: String?, dbQueue: FMDatabaseQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, sortOrder = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid = ?", values: [folderUuid ?? NSNull(), sortOrder, podcastUuid], methodName: "PodcastDataManager.updatePodcastFolder", onQueue: dbQueue)
        cachePodcasts(dbQueue: dbQueue)
    }

    func savePushSetting(podcast: Podcast, pushEnabled: Bool, dbQueue: FMDatabaseQueue) {
        podcast.pushEnabled = pushEnabled
        savePushSetting(podcastUuid: podcast.uuid, pushEnabled: pushEnabled, dbQueue: dbQueue)
    }

    func savePushSetting(podcastUuid: String, pushEnabled: Bool, dbQueue: FMDatabaseQueue) {
        saveSingleValue(name: "pushEnabled", value: pushEnabled, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func saveAutoAddToUpNext(podcastUuid: String, autoAddToUpNext: Int32, dbQueue: FMDatabaseQueue) {
        saveSingleValue(name: "autoAddToUpNext", value: autoAddToUpNext, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func setPodcastImageVersion(podcastUuid: String, version: Int, dbQueue: FMDatabaseQueue) {
        saveSingleValue(name: "lastColorDownloadDate", value: NSNull(), podcastUuid: podcastUuid, dbQueue: dbQueue)
        saveSingleValue(name: "colorVersion", value: version, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func savePodcastDownloadSetting(_ setting: AutoDownloadSetting, podcastUuid: String, dbQueue: FMDatabaseQueue) {
        saveSingleValue(name: "autoDownloadSetting", value: setting.rawValue, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func saveAutoArchiveLimit(podcast: Podcast, limit: Int32, dbQueue: FMDatabaseQueue) {
        podcast.autoArchiveEpisodeLimit = limit
        saveSingleValue(name: "episodeKeepSetting", value: limit, podcastUuid: podcast.uuid, dbQueue: dbQueue)
    }

    func delete(podcast: Podcast, dbQueue: FMDatabaseQueue) {
        DataHelper.run(query: "DELETE FROM \(DataManager.podcastTableName) WHERE uuid = ?", values: [podcast.uuid], methodName: "PodcastDataManager.delete", onQueue: dbQueue)
        cachePodcasts(dbQueue: dbQueue)
    }

    func markAllSynced(dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: SyncStatus.synced.rawValue, propertyName: "syncStatus", subscribedOnly: false, dbQueue: dbQueue)
    }

    func markAllUnsynced(dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: SyncStatus.notSynced.rawValue, propertyName: "syncStatus", subscribedOnly: true, dbQueue: dbQueue)
    }

    func markAllUnsyncedWhereLastSyncAtNot(_ lastSyncAt: String, dbQueue: FMDatabaseQueue) {
        let query = "UPDATE \(DataManager.podcastTableName) SET syncStatus = \(SyncStatus.notSynced.rawValue) WHERE subscribed = 1 AND fullSyncLastSyncAt <> ?"
        DataHelper.run(query: query, values: [lastSyncAt], methodName: "PodcastDataManager.markAllUnsyncedWhereLastSyncAtNot", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func setPushForAllPodcasts(pushEnabled: Bool, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: pushEnabled, propertyName: "pushEnabled", subscribedOnly: true, dbQueue: dbQueue)
    }

    func saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: Int32, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: autoAddToUpNext, propertyName: "autoAddToUpNext", subscribedOnly: true, dbQueue: dbQueue)
    }

    func updateAutoAddToUpNext(to value: AutoAddToUpNextSetting, for podcasts: [Podcast], in dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                let uuids = podcasts.map { $0.uuid }

                let query = """
                UPDATE \(DataManager.podcastTableName)
                SET autoAddToUpNext = ?
                AND uuid IN (\(DataHelper.convertArrayToInString(uuids)))
                """
                try db.executeUpdate(query, values: [value.rawValue])
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
            }
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    func setDownloadSettingForAllPodcasts(setting: AutoDownloadSetting, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: setting.rawValue, propertyName: "autoDownloadSetting", subscribedOnly: true, dbQueue: dbQueue)
    }

    func setOnAllPodcasts(value: Any, propertyName: String, subscribedOnly: Bool, dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                var query = "UPDATE \(DataManager.podcastTableName) SET \(propertyName) = ?"
                if subscribedOnly {
                    query += " WHERE subscribed = 1"
                }
                try db.executeUpdate(query, values: [value])
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
            }
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    func saveSortOrders(podcasts: [Podcast], dbQueue: FMDatabaseQueue) {
        dbQueue.inTransaction { db, _ in
            do {
                for podcast in podcasts {
                    try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET sortOrder = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE id = ?", values: [podcast.sortOrder, podcast.id])
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.saveSortOrders error: \(error)")
            }
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    func removeAllPodcastsFromFolder(folderUuid: String, dbQueue: FMDatabaseQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", values: [folderUuid], methodName: "PodcastDataManager.removeAllPodcastsFromFolder", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func removeAllPodcastsFromAllFolders(dbQueue: FMDatabaseQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL", values: nil, methodName: "PodcastDataManager.removeAllPodcastsFromAllFolders", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func updateAllPodcastGrouping(to grouping: PodcastGrouping, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: grouping.rawValue, propertyName: "episodeGrouping", subscribedOnly: true, dbQueue: dbQueue)
    }

    func updateAllShowArchived(to showArchived: Bool, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: showArchived, propertyName: "showArchived", subscribedOnly: true, dbQueue: dbQueue)
    }

    func setAllPodcastImageVersions(to version: Int, dbQueue: FMDatabaseQueue) {
        setOnAllPodcasts(value: NSNull(), propertyName: "lastColorDownloadDate", subscribedOnly: true, dbQueue: dbQueue)
        setOnAllPodcasts(value: version, propertyName: "colorVersion", subscribedOnly: true, dbQueue: dbQueue)
    }

    private func saveSingleValue(name: String, value: Any?, podcastUuid: String, dbQueue: FMDatabaseQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET \(name) = ? WHERE uuid = ?", values: [value ?? NSNull(), podcastUuid], methodName: "PodcastDataManager.saveSingleValue", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    // MARK: - Caching

    private func cachePodcasts(dbQueue: FMDatabaseQueue) {
        let trace = TraceManager.shared.beginTracing(eventName: "DATABASE_PODCAST_CACHE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.podcastTableName) ORDER BY sortOrder ASC", values: nil)
                defer { resultSet.close() }

                var newPodcasts = [Podcast]()
                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    newPodcasts.append(podcast)
                }
                cachedPodcastsQueue.sync {
                    cachedPodcasts = newPodcasts
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.cachePodcasts error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createPodcastFrom(resultSet rs: FMResultSet) -> Podcast {
        Podcast.from(resultSet: rs)
    }

    private func createValuesFrom(podcast: Podcast, includeIdForWhere: Bool = false) -> [Any] {
        var values = [Any]()
        values.append(podcast.id)
        values.append(DBUtils.nullIfNil(value: podcast.addedDate))
        values.append(podcast.autoDownloadSetting)
        values.append(podcast.autoAddToUpNext)
        values.append(podcast.autoArchiveEpisodeLimit)
        values.append(DBUtils.nullIfNil(value: podcast.backgroundColor))
        values.append(DBUtils.nullIfNil(value: podcast.detailColor))
        values.append(DBUtils.nullIfNil(value: podcast.primaryColor))
        values.append(DBUtils.nullIfNil(value: podcast.secondaryColor))
        values.append(DBUtils.nullIfNil(value: podcast.lastColorDownloadDate))
        values.append(DBUtils.nullIfNil(value: podcast.imageURL))
        values.append(DBUtils.nullIfNil(value: podcast.latestEpisodeUuid))
        values.append(DBUtils.nullIfNil(value: podcast.latestEpisodeDate))
        values.append(DBUtils.nullIfNil(value: podcast.mediaType))
        values.append(DBUtils.nullIfNil(value: podcast.lastThumbnailDownloadDate))
        values.append(podcast.thumbnailStatus)
        values.append(DBUtils.nullIfNil(value: podcast.podcastUrl))
        values.append(DBUtils.nullIfNil(value: podcast.author))
        values.append(podcast.playbackSpeed)
        values.append(podcast.boostVolume)
        values.append(podcast.trimSilenceAmount)
        values.append(DBUtils.nullIfNil(value: podcast.podcastCategory))
        values.append(DBUtils.nullIfNil(value: podcast.podcastDescription))
        values.append(podcast.sortOrder)
        values.append(podcast.startFrom)
        values.append(podcast.skipLast)
        values.append(podcast.subscribed)
        values.append(DBUtils.nullIfNil(value: podcast.title))
        values.append(podcast.uuid)
        values.append(podcast.syncStatus)
        values.append(podcast.colorVersion)
        values.append(podcast.pushEnabled)
        values.append(podcast.episodeSortOrder)
        values.append(DBUtils.nullIfNil(value: podcast.showType))
        values.append(DBUtils.nullIfNil(value: podcast.estimatedNextEpisode))
        values.append(DBUtils.nullIfNil(value: podcast.episodeFrequency))
        values.append(DBUtils.nullIfNil(value: podcast.lastUpdatedAt))
        values.append(podcast.excludeFromAutoArchive)
        values.append(podcast.overrideGlobalEffects)
        values.append(podcast.overrideGlobalArchive)
        values.append(podcast.autoArchivePlayedAfter)
        values.append(podcast.autoArchiveInactiveAfter)
        values.append(podcast.episodeGrouping)
        values.append(podcast.isPaid)
        values.append(podcast.licensing)
        values.append(DBUtils.nullIfNil(value: podcast.fullSyncLastSyncAt))
        values.append(podcast.showArchived)
        values.append(podcast.refreshAvailable)
        values.append(DBUtils.nullIfNil(value: podcast.folderUuid))

        if includeIdForWhere {
            values.append(podcast.id)
        }

        return values
    }

    private func addedDateSort(p1: Podcast, p2: Podcast) -> Bool {
        guard let date1 = p1.addedDate, let date2 = p2.addedDate else { return false }

        return PodcastSorter.dateAddedSort(date1: date1, date2: date2)
    }

    private func titleSort(p1: Podcast, p2: Podcast) -> Bool {
        guard let title1 = p1.title, let title2 = p2.title else { return false }

        return PodcastSorter.titleSort(title1: title1, title2: title2)
    }
}
