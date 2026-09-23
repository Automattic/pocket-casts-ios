import PocketCastsUtils
import Foundation
import GRDB

extension Podcast: Sortable {
    public var itemUUID: String {
        uuid
    }

    public var itemTitle: String? {
        title
    }
}

class PodcastDataManager {
    private let cachedPodcasts = Mutex([String: Podcast]())

    func setup(dbQueue: GRDBQueue) {
        cachePodcasts(dbQueue: dbQueue)
    }

    // MARK: - Queries

    func allPodcasts(includeUnsubscribed: Bool, reloadFromDatabase: Bool, dbQueue: GRDBQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed(), !includeUnsubscribed { continue }
                allPodcasts.append(podcast)
            }
        }

        return allPodcasts
    }

    func allPodcastsOrderedByAddedDate(reloadFromDatabase: Bool, dbQueue: GRDBQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            addedDateSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByTitle(reloadFromDatabase: Bool, dbQueue: GRDBQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                allPodcasts.append(podcast)
            }
        }

        return allPodcasts.sorted(by: { podcast1, podcast2 -> Bool in
            titleSort(p1: podcast1, p2: podcast2)
        })
    }

    func allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: Bool, inFolderUuid: String? = nil, dbQueue: GRDBQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        dbQueue.read { db in
            do {
                var values: [Any]?
                var whereClause = "WHERE p.subscribed = 1"
                if let inFolderUuid {
                    whereClause += " AND p.folderUuid = ?"
                    values = [inFolderUuid]
                }
                let query = "SELECT DISTINCT p.id, p.* FROM \(DataManager.podcastTableName) p LEFT JOIN \(DataManager.episodeTableName) e ON p.id = e.podcast_id AND e.id = (SELECT e.id FROM \(DataManager.episodeTableName) e WHERE e.podcast_id = p.id AND e.playingStatus != 3 AND e.archived = 0 ORDER BY e.publishedDate DESC LIMIT 1) \(whereClause) ORDER BY CASE WHEN e.publishedDate IS NULL THEN 1 ELSE 0 END, e.publishedDate DESC, p.latestEpisodeDate DESC"
                let resultSet = try db.executeQuery(query, values: values)

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

    func allPodcastsOrderedByLastPlayedEpisodes(reloadFromDatabase: Bool, inFolderUuid: String? = nil, dbQueue: GRDBQueue) -> [Podcast] {
        if reloadFromDatabase { cachePodcasts(dbQueue: dbQueue) }

        var allPodcasts = [Podcast]()
        dbQueue.read { db in
            do {
                var values: [Any]?
                var whereClause = "WHERE p.subscribed = 1"
                if let inFolderUuid {
                    whereClause += " AND p.folderUuid = ?"
                    values = [inFolderUuid]
                }
                let query = "SELECT DISTINCT p.id, p.* FROM \(DataManager.podcastTableName) p LEFT JOIN \(DataManager.episodeTableName) e ON p.id = e.podcast_id AND e.id = (SELECT e.id FROM \(DataManager.episodeTableName) e WHERE e.podcast_id = p.id ORDER BY e.lastPlaybackInteractionDate DESC LIMIT 1) \(whereClause) ORDER BY CASE WHEN e.lastPlaybackInteractionDate IS NULL THEN 1 ELSE 0 END, e.lastPlaybackInteractionDate DESC"
                let resultSet = try db.executeQuery(query, values: values)

                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    allPodcasts.append(podcast)
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.allPodcastsOrderedByLastPlayedEpisodes error: \(error)")
            }
        }

        return allPodcasts
    }

    /// Returns 5 random podcasts from the DB
    /// This is here for development purposes.
    func randomPodcasts(dbQueue: GRDBQueue) -> [Podcast] {
        var allPodcasts = [Podcast]()
        dbQueue.read { db in
            do {
                let query = "SELECT * FROM SJPodcast ORDER BY RANDOM() LIMIT 5"
                let resultSet = try db.executeQuery(query, values: nil)

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

    func allUnsubscribedPodcastUuids(dbQueue: GRDBQueue) -> [String] {
        var allUnsubscribed = [String]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast.uuid)
            }
        }

        return allUnsubscribed
    }

    func allUnsubscribedPodcasts(dbQueue: GRDBQueue) -> [Podcast] {
        var allUnsubscribed = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed() { continue }

                allUnsubscribed.append(podcast)
            }
        }

        return allUnsubscribed
    }

    func allPodcastsInFolder(folder: Folder, dbQueue: GRDBQueue) -> [Podcast] {
        let sortOrder = folder.folderSort()

        // newest episode release date is a special case we handle at the database level
        if sortOrder == .episodeDateNewestToOldest {
            return allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: false, inFolderUuid: folder.uuid, dbQueue: dbQueue)
        }

        // newest episode release date is a special case we handle at the database level
        if sortOrder == .recentlyPlayed {
            return allPodcastsOrderedByLastPlayedEpisodes(reloadFromDatabase: false, inFolderUuid: folder.uuid, dbQueue: dbQueue)
        }

        // the other 3 cases we do in memory
        var allPodcastsInFolder: [Podcast] = []
        cachedPodcasts.withLock { cachedPodcasts in
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

    func countOfPodcastsInFolder(folder: Folder?, dbQueue: GRDBQueue) -> Int {
        cachedPodcasts.withLock { cachedPodcasts in
            cachedPodcasts.values.filter { $0.isSubscribed() && $0.folderUuid == folder?.uuid }.count
        }
    }

    func allPaidPodcasts(dbQueue: GRDBQueue) -> [Podcast] {
        var allPaid = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if !podcast.isPaid { continue }

                allPaid.append(podcast)
            }
        }

        return allPaid
    }

    func allUnsynced(dbQueue: GRDBQueue) -> [Podcast] {
        var unsyncedPodcasts = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if podcast.syncStatus == SyncStatus.notSynced.rawValue {
                    unsyncedPodcasts.append(podcast)
                }
            }
        }

        return unsyncedPodcasts
    }

    func allOverrideGlobalArchivePodcasts(dbQueue: GRDBQueue) -> [Podcast] {
        var podcastsOverrideArchive = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if podcast.isSubscribed(), podcast.overrideGlobalArchive {
                    podcastsOverrideArchive.append(podcast)
                }
            }
        }

        return podcastsOverrideArchive
    }

    func find(uuid: String, includeUnsubscribed: Bool, dbQueue: GRDBQueue) -> Podcast? {
        cachedPodcasts.withLock { cachedPodcasts in
            guard let podcast = cachedPodcasts[uuid] else { return nil }

            if !includeUnsubscribed, !podcast.isSubscribed() { return nil }

            return podcast
        }
    }

    func searchPodcasts(term: String, dbQueue: GRDBQueue) -> [Podcast] {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return [] }

        let locale = Locale.current
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        var matchingPodcasts = [Podcast]()
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                guard podcast.isSubscribed() else { continue }

                if podcast.title?.range(of: trimmedTerm, options: options, range: nil, locale: locale) != nil {
                    matchingPodcasts.append(podcast)
                    continue
                }

                if podcast.author?.range(of: trimmedTerm, options: options, range: nil, locale: locale) != nil {
                    matchingPodcasts.append(podcast)
                }
            }
        }

        return matchingPodcasts.sorted(by: { lhs, rhs in
            PodcastSorter.sortByNameAndUUID(item1: lhs, item2: rhs)
        })
    }

    func count(dbQueue: GRDBQueue) -> Int {
        var count = 0
        cachedPodcasts.withLock { cachedPodcasts in
            for podcast in cachedPodcasts.values {
                if !podcast.isSubscribed() { continue }

                count += 1
            }
        }

        return count
    }

    func unfinishedCounts(dbQueue: GRDBQueue) -> [String: Int32] {
        var counts = [String: Int32]()
        dbQueue.read { db in
            do {
                let query = "SELECT p.uuid as uuid, count(e.id) as count FROM \(DataManager.episodeTableName) e, \(DataManager.podcastTableName) p WHERE e.podcast_id = p.id AND playingStatus <> \(PlayingStatus.completed.rawValue) AND archived = 0 GROUP BY p.uuid"
                let rs = try db.executeQuery(query, values: nil)

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

    func save(podcast: Podcast, dbQueue: GRDBQueue) {
        if podcast.id == 0 {
            podcast.id = DBUtils.generateUniqueId()
        }

        do {
            try dbQueue.dbPool.write { db in
                try podcast.save(db)
            }
        } catch {
            FileLog.shared.addMessage("PodcastDataManager.save error: \(error)")
        }
        cachePodcasts(dbQueue: dbQueue)
    }

    func bulkSetFolderUuid(folderUuid: String, podcastUuids: [String], dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                // clear out any that shouldn't be in this folder
                try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", values: [folderUuid])

                // then set all the ones that should
                if !podcastUuids.isEmpty {
                    try db.executeUpdate("UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid IN (\(DataHelper.convertArrayToInString(podcastUuids)))", values: [folderUuid])
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.bulkSetFolderUuid error: \(error)")
            }
        }
        cachePodcasts(dbQueue: dbQueue)
    }

    func updatePodcastFolder(podcastUuid: String, sortOrder: Int32, folderUuid: String?, dbQueue: GRDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = ?, sortOrder = ?, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE uuid = ?", values: [folderUuid ?? NSNull(), sortOrder, podcastUuid], methodName: "PodcastDataManager.updatePodcastFolder", onQueue: dbQueue)
        cachePodcasts(dbQueue: dbQueue)
    }

    func savePushSetting(podcast: Podcast, pushEnabled: Bool, dbQueue: GRDBQueue) {
        podcast.pushEnabled = pushEnabled
        savePushSetting(podcastUuid: podcast.uuid, pushEnabled: pushEnabled, dbQueue: dbQueue)
    }

    func savePushSetting(podcastUuid: String, pushEnabled: Bool, dbQueue: GRDBQueue) {
        saveSingleValue(name: "pushEnabled", value: pushEnabled, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func saveAutoAddToUpNext(podcastUuid: String, autoAddToUpNext: Int32, dbQueue: GRDBQueue) {
        saveSingleValue(name: "autoAddToUpNext", value: autoAddToUpNext, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func setPodcastImageVersion(podcastUuid: String, version: Int, dbQueue: GRDBQueue) {
        saveSingleValue(name: "lastColorDownloadDate", value: NSNull(), podcastUuid: podcastUuid, dbQueue: dbQueue)
        saveSingleValue(name: "colorVersion", value: version, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func savePodcastDownloadSetting(_ setting: AutoDownloadSetting, podcastUuid: String, dbQueue: GRDBQueue) {
        saveSingleValue(name: "autoDownloadSetting", value: setting.rawValue, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    func saveAutoArchiveLimit(podcast: Podcast, limit: Int32, dbQueue: GRDBQueue) {
        podcast.autoArchiveEpisodeLimit = limit
        podcast.settings.autoArchiveEpisodeLimit = limit
        saveSingleValue(name: "episodeKeepSetting", value: limit, podcastUuid: podcast.uuid, dbQueue: dbQueue)
    }

    func delete(podcast: Podcast, dbQueue: GRDBQueue) {
        DataHelper.run(query: "DELETE FROM \(DataManager.podcastTableName) WHERE uuid = ?", values: [podcast.uuid], methodName: "PodcastDataManager.delete", onQueue: dbQueue)
        cachePodcasts(dbQueue: dbQueue)
    }

    func markAllSynced(dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: SyncStatus.synced.rawValue, propertyName: "syncStatus", subscribedOnly: false, dbQueue: dbQueue)
    }

    func markAllUnsynced(dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: SyncStatus.notSynced.rawValue, propertyName: "syncStatus", subscribedOnly: true, dbQueue: dbQueue)
    }

    func markAllUnsyncedWhereLastSyncAtNot(_ lastSyncAt: String, dbQueue: GRDBQueue) {
        let query = "UPDATE \(DataManager.podcastTableName) SET syncStatus = \(SyncStatus.notSynced.rawValue) WHERE subscribed = 1 AND fullSyncLastSyncAt <> ?"
        DataHelper.run(query: query, values: [lastSyncAt], methodName: "PodcastDataManager.markAllUnsyncedWhereLastSyncAtNot", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func setPushForAllPodcasts(pushEnabled: Bool, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: pushEnabled, propertyName: "pushEnabled", subscribedOnly: true, dbQueue: dbQueue)
    }

    func saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: Int32, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: autoAddToUpNext, propertyName: "autoAddToUpNext", subscribedOnly: true, dbQueue: dbQueue)
    }

    func updateAutoAddToUpNext(to value: AutoAddToUpNextSetting, for podcasts: [Podcast], in dbQueue: GRDBQueue) {
        dbQueue.write { db in
            do {
                let uuids = podcasts.map { $0.uuid }

                let query = """
                UPDATE \(DataManager.podcastTableName)
                SET autoAddToUpNext = ?
                WHERE uuid IN (\(DataHelper.convertArrayToInString(uuids)))
                """
                try db.executeUpdate(query, values: [value.rawValue])
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.setOnAllPodcasts error: \(error)")
            }
        }

        cachePodcasts(dbQueue: dbQueue)
    }

    func setDownloadSettingForAllPodcasts(setting: AutoDownloadSetting, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: setting.rawValue, propertyName: "autoDownloadSetting", subscribedOnly: true, dbQueue: dbQueue)
    }

    func setOnAllPodcasts(value: Any, propertyName: String, subscribedOnly: Bool, dbQueue: GRDBQueue) {
        dbQueue.write { db in
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

    func saveSortOrders(podcasts: [Podcast], dbQueue: GRDBQueue) {
        dbQueue.write { db in
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

    func removeAllPodcastsFromFolder(folderUuid: String, dbQueue: GRDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL, syncStatus = \(SyncStatus.notSynced.rawValue) WHERE folderUuid = ?", values: [folderUuid], methodName: "PodcastDataManager.removeAllPodcastsFromFolder", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func removeAllPodcastsFromAllFolders(dbQueue: GRDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET folderUuid = NULL", values: nil, methodName: "PodcastDataManager.removeAllPodcastsFromAllFolders", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    func updateAllPodcastGrouping(to grouping: PodcastGrouping, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: grouping.rawValue, propertyName: "episodeGrouping", subscribedOnly: true, dbQueue: dbQueue)
    }

    func updateAllShowArchived(to showArchived: Bool, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: showArchived, propertyName: "showArchived", subscribedOnly: true, dbQueue: dbQueue)
    }

    func setAllPodcastImageVersions(to version: Int, dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: NSNull(), propertyName: "lastColorDownloadDate", subscribedOnly: true, dbQueue: dbQueue)
        setOnAllPodcasts(value: version, propertyName: "colorVersion", subscribedOnly: true, dbQueue: dbQueue)
    }

    func clearLastUpdatedAtForAllPodcasts(dbQueue: GRDBQueue) {
        setOnAllPodcasts(value: NSNull(), propertyName: "lastUpdatedAt", subscribedOnly: true, dbQueue: dbQueue)
    }

    private func saveSingleValue(name: String, value: Any?, podcastUuid: String, dbQueue: GRDBQueue) {
        DataHelper.run(query: "UPDATE \(DataManager.podcastTableName) SET \(name) = ? WHERE uuid = ?", values: [value ?? NSNull(), podcastUuid], methodName: "PodcastDataManager.saveSingleValue", onQueue: dbQueue)

        cachePodcasts(dbQueue: dbQueue)
    }

    // MARK: - Caching

    private func cachePodcasts(dbQueue: GRDBQueue) {
        let trace = TraceManager.shared.beginTracing(eventName: "DATABASE_PODCAST_CACHE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT * from \(DataManager.podcastTableName)", values: nil)

                var newPodcasts = [String: Podcast]()
                while resultSet.next() {
                    let podcast = self.createPodcastFrom(resultSet: resultSet)
                    newPodcasts[podcast.uuid] = podcast
                }
                cachedPodcasts.withLock { cachedPodcasts in
                    cachedPodcasts = newPodcasts
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.cachePodcasts error: \(error)")
            }
        }
    }

    // MARK: - Conversion

    private func createPodcastFrom(resultSet rs: PCDBResultSet) -> Podcast {
        Podcast.from(resultSet: rs)
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
