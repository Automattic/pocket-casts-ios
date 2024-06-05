import FMDB
import GRDB
import PocketCastsUtils

class PodcastDataManager {
    private var cachedPodcasts = [String: Podcast]()
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
        "folderUuid",
    ]

    func setup(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    // MARK: - Queries

    func allPodcasts(includeUnsubscribed: Bool, reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue, dbPool: dbPool) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed(), !includeUnsubscribed { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts
    }

    func allPodcastsOrderedByAddedDate(reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue, dbPool: dbPool) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            addedDateSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByTitle(reloadFromDatabase: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue, dbPool: dbPool) }

        var allPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            titleSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: Bool, inFolderUuid: String? = nil, dbQueue: FMDatabaseQueue, dbPool: DatabasePool? = nil) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue, dbPool: dbPool) }

        var allPodcasts = [Podcast]()

        if let dbPool {
            try! dbPool.read { db in
                var values: [Any] = []
                var whereClause = "WHERE p.subscribed = 1"
                if let inFolderUuid = inFolderUuid {
                    whereClause += " AND p.folderUuid = ?"
                    values = [inFolderUuid]
                }
                let query = "SELECT DISTINCT p.id, p.* FROM \(DataManager.podcastTableName) p LEFT JOIN \(DataManager.episodeTableName) e ON p.id = e.podcast_id AND e.id = (SELECT e.id FROM \(DataManager.episodeTableName) e WHERE e.podcast_id = p.id AND e.playingStatus != 3 AND e.archived = 0 ORDER BY e.publishedDate DESC LIMIT 1) \(whereClause) ORDER BY CASE WHEN e.publishedDate IS NULL THEN 1 ELSE 0 END, e.publishedDate DESC, p.latestEpisodeDate DESC"

                let rows = try Row.fetchCursor(db, sql: query, arguments: StatementArguments(values)!)

                while let row = try rows.next() {
                    let podcast = self.createPodcastFrom(row: row)
                    allPodcasts.append(podcast)
                }
            }

            return allPodcasts
        }

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
    func randomPodcasts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        var allPodcasts = [Podcast]()
        do {
            try dbPool.read { db in
                let query = "SELECT * FROM SJPodcast ORDER BY RANDOM() LIMIT 5"
                let rows = try Row.fetchCursor(db, sql: query)

                while let row = try rows.next() {
                    let podcast = self.createPodcastFrom(row: row)
                    allPodcasts.append(podcast)
                }
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.randomPodcasts error: \(error)")
        }

        return allPodcasts
    }

    func allUnsubscribedPodcastUuids(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [String] {
        var allUnsubscribed = [String]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast.uuid)
            }
        }

        return allUnsubscribed
    }

    func allUnsubscribedPodcasts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        var allUnsubscribed = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast)
            }
        }

        return allUnsubscribed
    }

    func allPodcastsInFolder(folder: Folder, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        let sortOrder = folder.folderSort()

        // newest episode release date is a special case we handle at the database level
        if sortOrder == .episodeDateNewestToOldest {
            return allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: false, inFolderUuid: folder.uuid, dbQueue: dbQueue, dbPool: dbPool)
        }

        // the other 3 cases we do in memory
        var allPodcastsInFolder: [Podcast] = []
        cachedPodcastsQueue.sync {
            allPodcastsInFolder = cachedPodcasts.values.filter { $0.isSubscribed() && $0.folderUuid == folder.uuid }
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

    func countOfPodcastsInFolder(folder: Folder?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        cachedPodcastsQueue.sync {
            cachedPodcasts.values.filter { $0.isSubscribed() && $0.folderUuid == folder?.uuid }.count
        }
    }

    func allPaidPodcasts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        var allPaid = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if !podcast.isPaid { continue }

                allPaid.append(podcast)
            }
        }

        return allPaid
    }

    func allUnsynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        var unsyncedPodcasts = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if podcast.syncStatus == SyncStatus.notSynced.rawValue {
                    unsyncedPodcasts.append(podcast)
                }
            }
        }

        return unsyncedPodcasts
    }

    func allOverrideGlobalArchivePodcasts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [Podcast] {
        var podcastsOverrideArchive = [Podcast]()
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed(), podcast.isAutoArchiveOverridden {
                    podcastsOverrideArchive.append(podcast)
                }
            }
        }

        return podcastsOverrideArchive
    }

    func find(uuid: String, includeUnsubscribed: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Podcast? {
        cachedPodcastsQueue.sync {
            guard let podcast = cachedPodcasts[uuid] else { return nil }

            if !includeUnsubscribed, !podcast.isSubscribed() { return nil }

            return podcast
        }
    }

    func count(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> Int {
        var count = 0
        cachedPodcastsQueue.sync {
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                count += 1
            }
        }

        return count
    }

    func unfinishedCounts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) -> [String: Int32] {
        var counts = [String: Int32]()
        do {
            try dbPool.read { db in
                let query = "SELECT p.uuid as uuid, count(e.id) as count FROM \(DataManager.episodeTableName) e, \(DataManager.podcastTableName) p WHERE e.podcast_id = p.id AND playingStatus <> \(PlayingStatus.completed.rawValue) AND archived = 0 GROUP BY p.uuid"
                let rows = try Row.fetchCursor(db, sql: query)

                while let row = try rows.next() {
                    guard let uuid: String = row["uuid"] else { continue }
                    let count: Int32 = row["count"]

                    counts[uuid] = count
                }
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.unfinishedCounts error: \(error)")
        }

        return counts
    }

    // MARK: - Updates

    func save(podcast: Podcast, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        // Get the existing podcast to compare if folder is being changed
        let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcast.uuid)

        do {
            try dbPool.write { db in
                if podcast.id == 0 {
                    podcast.id = DBUtils.generateUniqueId()
                    try db.execute(sql: "INSERT INTO \(DataManager.podcastTableName) (\(self.columnNames.joined(separator: ","))) VALUES \(DBUtils.valuesQuestionMarks(amount: self.columnNames.count))", arguments: StatementArguments(self.createValuesFrom(podcast: podcast))!)
                } else {
                    let setStatement = "\(self.columnNames.joined(separator: " = ?, ")) = ?"
                    try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET \(setStatement) WHERE id = ?", arguments: StatementArguments(self.createValuesFrom(podcast: podcast, includeIdForWhere: true))!)

                    // If changing folder, log it
                    if podcast.folderUuid != existingPodcast?.folderUuid {
                        FileLog.shared.foldersIssue("PodcastDataManager: update \(podcast.title ?? "") folder from \(existingPodcast?.folderUuid ?? "nil") to \(podcast.folderUuid ?? "nil")")
                    }
                }
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.save error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func bulkSetFolderUuid(folderUuid: String, podcastUuids: [String], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {

        do {
            try dbPool.write { db in
                // clear out any that shouldn't be in this folder
                try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", arguments: [folderUuid])

                // then set all the ones that should
                if podcastUuids.count > 0 {
                    try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid IN (\(DataHelper.convertArrayToInString(podcastUuids)))", arguments: [folderUuid])
                }
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.bulkSetFolderUuid error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func updatePodcastFolder(podcastUuid: String, sortOrder: Int32, folderUuid: String?, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, sortOrder = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid = ?", arguments: [folderUuid ?? NSNull(), sortOrder, podcastUuid])
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.updatePodcastFolder error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func savePushSetting(podcast: Podcast, pushEnabled: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        podcast.isPushEnabled = pushEnabled
        savePushSetting(podcastUuid: podcast.uuid, pushEnabled: pushEnabled, dbQueue: dbQueue, dbPool: dbPool)
    }

    func savePushSetting(podcastUuid: String, pushEnabled: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if FeatureFlag.newSettingsStorage.enabled {
            saveSingleSetting("notification", value: pushEnabled, podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
        }
        saveSingleValue(name: "pushEnabled", value: pushEnabled, podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveAutoAddToUpNext(podcastUuid: String, autoAddToUpNext: Int32, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if FeatureFlag.newSettingsStorage.enabled {
            if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) {
                if let setting = AutoAddToUpNextSetting(rawValue: autoAddToUpNext) {
                    podcast.setAutoAddToUpNext(setting: setting)
                    podcast.syncStatus = SyncStatus.notSynced.rawValue
                    save(podcast: podcast, dbQueue: dbQueue, dbPool: dbPool)
                } else {
                    FileLog.shared.addMessage("Podcast Data: Failed to create AutoAddToUpNextSetting type for saving")
                }
            } else {
                FileLog.shared.addMessage("Podcast Data: Couldn't find podcast for saving AutoAddToUpNext with UUID: \(podcastUuid)")
            }
        }
        saveSingleValue(name: "autoAddToUpNext", value: autoAddToUpNext, podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func setPodcastImageVersion(podcastUuid: String, version: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        saveSingleValue(name: "lastColorDownloadDate", value: NSNull(), podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
        saveSingleValue(name: "colorVersion", value: version, podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func savePodcastDownloadSetting(_ setting: AutoDownloadSetting, podcastUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        saveSingleValue(name: "autoDownloadSetting", value: setting.rawValue, podcastUuid: podcastUuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveAutoArchiveLimit(podcast: Podcast, limit: Int32, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        podcast.autoArchiveEpisodeLimitCount = limit
        podcast.settings.autoArchiveEpisodeLimit = limit
        saveSingleValue(name: "episodeKeepSetting", value: limit, podcastUuid: podcast.uuid, dbQueue: dbQueue, dbPool: dbPool)
    }

    func delete(podcast: Podcast, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "DELETE FROM \(DataManager.podcastTableName) WHERE uuid = ?", values: [podcast.uuid], methodName: "PodcastDataManager.delete", onQueue: dbQueue, dbPool: dbPool)
        cachePodcasts(dbQueue: dbQueue)
    }

    func markAllSynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: SyncStatus.synced.rawValue, propertyName: "syncStatus", subscribedOnly: false, dbQueue: dbQueue, dbPool: dbPool)
    }

    func markAllUnsynced(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: SyncStatus.notSynced.rawValue, propertyName: "syncStatus", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    func markAllUnsyncedWhereLastSyncAtNot(_ lastSyncAt: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        let query = "UPDATE \(DataManager.podcastTableName) SET syncStatus = \(SyncStatus.notSynced.rawValue) WHERE subscribed = 1 AND fullSyncLastSyncAt <> ?"
        DataHelper.run(query: query, values: [lastSyncAt], methodName: "PodcastDataManager.markAllUnsyncedWhereLastSyncAtNot", onQueue: dbQueue, dbPool: dbPool)

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func setPushForAllPodcasts(pushEnabled: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if FeatureFlag.newSettingsStorage.enabled {
            setOnAllPodcasts(value: pushEnabled, settingName: "notification", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
        }
        setOnAllPodcasts(value: pushEnabled, propertyName: "pushEnabled", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    func saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: Int32, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        if FeatureFlag.newSettingsStorage.enabled {
            setOnAllPodcasts(value: autoAddToUpNext, settingName: "addToUpNext", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
        }
        setOnAllPodcasts(value: autoAddToUpNext, propertyName: "autoAddToUpNext", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateAutoAddToUpNext(to value: AutoAddToUpNextSetting, for podcasts: [Podcast], in dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                let uuids = podcasts.map { $0.uuid }

                if FeatureFlag.newSettingsStorage.enabled {
                    let query = """
                    SELECT json_patch('setting', '{\"addToUpNext\": {\"value\": \(value)}}')
                    WHERE uuid IN (\(DataHelper.convertArrayToInString(uuids)))
                    FROM \(DataManager.podcastTableName)"
                    """
                    try db.execute(sql: query, arguments: [value.rawValue])
                }

                let query = """
                UPDATE \(DataManager.podcastTableName)
                SET autoAddToUpNext = ?
                AND uuid IN (\(DataHelper.convertArrayToInString(uuids)))
                """
                try db.execute(sql: query, arguments: [value.rawValue])
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func setDownloadSettingForAllPodcasts(setting: AutoDownloadSetting, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: setting.rawValue, propertyName: "autoDownloadSetting", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    enum JSONError: Error {
        case failedStringConvert(String, Data)

        var description: String {
            switch self {
            case .failedStringConvert(let name, let data):
                "Failed to convert JSON to String for \(name) with \(data)"
            }
        }
    }

    func setOnAllPodcasts<Value: Codable & Equatable>(value: Value, settingName: String, subscribedOnly: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                let modified = ModifiedDate(wrappedValue: value, modifiedAt: Date())
                let json = try JSONEncoder().encode(modified)
                guard let jsonString = String(data: json, encoding: .utf8) else {
                    throw JSONError.failedStringConvert(settingName, json)
                }

                let query = """
                UPDATE \(DataManager.podcastTableName)
                SET settings = json_set(
                    \(DataManager.podcastTableName).settings,
                    '$.\(settingName)',
                    json('\(jsonString)')
                ), syncStatus = \(SyncStatus.notSynced.rawValue)
                """
                try db.execute(sql: query, arguments: [])
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func setOnAllPodcasts(value: DatabaseValueConvertible, propertyName: String, subscribedOnly: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {

        do {
            try dbPool.write { db in
                var query = "UPDATE \(DataManager.podcastTableName) SET \(propertyName) = ?"
                if subscribedOnly {
                    query += " WHERE subscribed = 1"
                }
                try db.execute(sql: query, arguments: [value])
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    func saveSortOrders(podcasts: [Podcast], dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                for podcast in podcasts {
                    try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET sortOrder = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE id = ?", arguments: [podcast.sortOrder, podcast.id])
                }
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.saveSortOrders error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func removeAllPodcastsFromFolder(folderUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", values: [folderUuid], methodName: "PodcastDataManager.removeAllPodcastsFromFolder", onQueue: dbQueue, dbPool: dbPool)

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func removeAllPodcastsFromAllFolders(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL", values: nil, methodName: "PodcastDataManager.removeAllPodcastsFromAllFolders", onQueue: dbQueue, dbPool: dbPool)

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateAllPodcastGrouping(to grouping: PodcastGrouping, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: grouping.rawValue, propertyName: "episodeGrouping", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    func updateAllShowArchived(to showArchived: Bool, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: showArchived, propertyName: "showArchived", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    func setAllPodcastImageVersions(to version: Int, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        setOnAllPodcasts(value: NSNull(), propertyName: "lastColorDownloadDate", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
        setOnAllPodcasts(value: version, propertyName: "colorVersion", subscribedOnly: true, dbQueue: dbQueue, dbPool: dbPool)
    }

    private func saveSingleValue(name: String, value: DatabaseValueConvertible?, podcastUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "UPDATE \(DataManager.podcastTableName) SET \(name) = ? WHERE uuid = ?", arguments: [value ?? NSNull(), podcastUuid])
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.saveSingleValue error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    private func saveSingleSetting<Value: Codable & Equatable>(_ name: String, value: Value, podcastUuid: String, dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {

        do {
            try dbPool.write { db in
                let modified = ModifiedDate(wrappedValue: value, modifiedAt: Date())
                let json = try JSONEncoder().encode(modified)
                guard let jsonString = String(data: json, encoding: .utf8) else {
                    throw JSONError.failedStringConvert(name, json)
                }

                let query = """
                UPDATE \(DataManager.podcastTableName)
                SET settings = json_set(
                    \(DataManager.podcastTableName).settings,
                    '$.notification',
                    json('\(jsonString)')
                ), syncStatus = \(SyncStatus.notSynced.rawValue)
                WHERE uuid = '\(podcastUuid)'
                """
                try db.execute(sql: query, arguments: [])
            }
        } catch let error {
            FileLog.shared.addMessage("PodcastDataManager.saveSingleSetting for \(name) error: \(error)")
        }

        cachePodcasts(dbQueue: dbQueue, dbPool: dbPool)
    }

    // MARK: - Caching

    private func cachePodcasts(dbQueue: FMDatabaseQueue, dbPool: DatabasePool? = nil) {
        let trace = TraceManager.shared.beginTracing(eventName: "DATABASE_PODCAST_CACHE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        if let dbPool {

            try! dbPool.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT * from \(DataManager.podcastTableName) ORDER BY sortOrder ASC")

                var newPodcasts = [String: Podcast]()
                while let row = try rows.next() {
                    let podcast = self.createPodcastFrom(row: row)
                    newPodcasts[podcast.uuid] = podcast
                }
                cachedPodcastsQueue.sync {
                    cachedPodcasts = newPodcasts
                }
            }

            return
        }

        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.podcastTableName) ORDER BY sortOrder ASC", values: nil)
                defer { resultSet.close() }

                var newPodcasts = [String: Podcast]()
                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    newPodcasts[podcast.uuid] = podcast
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

    private func createPodcastFrom(row: RowCursor.Element) -> Podcast {
        Podcast.from(row: row)
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
