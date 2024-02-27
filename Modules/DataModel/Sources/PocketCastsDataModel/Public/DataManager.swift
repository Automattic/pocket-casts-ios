import FMDB
import PocketCastsUtils
import SQLite3

public class DataManager {
    public static let podcastTableName = "SJPodcast"
    public static let episodeTableName = "SJEpisode"
    public static let userEpisodeTableName = "SJUserEpisode"
    public static let filtersTableName = "SJFilteredPlaylist"
    public static let playlistEpisodeTableName = "SJPlaylistEpisode"
    public static let upNextChangesTableName = "UpNextChanges"
    public static let folderTableName = "Folder"

    private let podcastManager = PodcastDataManager()
    private let upNextManager = UpNextDataManager()
    private let upNextChangesManager = UpNextChangesDataManager()
    private let filterManager = EpisodeFilterDataManager()
    private let episodeManager = EpisodeDataManager()
    private let userEpisodeManager = UserEpisodeDataManager()
    private let folderManager = FolderDataManager()
    private lazy var endOfYearManager = EndOfYearDataManager()

    public let autoAddCandidates: AutoAddCandidatesDataManager
    public let bookmarks: BookmarkDataManager

    private let dbQueue: FMDatabaseQueue

    public static let sharedManager = DataManager()

    /// Creates a DataManager using a queue that is persisted to a local SQLIte file
    public convenience init() {
        DataManager.ensureDbFolderExists()

        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        let dbQueue = FMDatabaseQueue(path: DataManager.pathToDb(), flags: flags)!

        self.init(dbQueue: dbQueue)
    }

    /// Creates a DataManager using the given `FMDatabaseQueue`.
    /// If `shouldCloseQueueAfterSetup` is true, `dbQueue.close()` is called after the schema is created, otherwise the queue is left open.
    public init(dbQueue: FMDatabaseQueue, shouldCloseQueueAfterSetup: Bool = true) {
        self.dbQueue = dbQueue

        dbQueue.inDatabase { db in
            DatabaseHelper.setup(db: db)
        }

        if shouldCloseQueueAfterSetup {
            // "You don't need to close it during the app lifecycle, unless you modify the schema." Since the above method can modify the schema, we do that here as recommended by the author of FMDB
            dbQueue.close()
        }

        // closing it above won't affect these calls, since they will re-open it
        podcastManager.setup(dbQueue: dbQueue)
        folderManager.setup(dbQueue: dbQueue)
        upNextManager.setup(dbQueue: dbQueue)

        autoAddCandidates = AutoAddCandidatesDataManager(dbQueue: dbQueue)
        bookmarks = BookmarkDataManager(dbQueue: dbQueue)
    }

    convenience init(endOfYearManager: EndOfYearDataManager) {
        self.init()
        self.endOfYearManager = endOfYearManager
    }

    // MARK: - Up Next

    public func allUpNextPlaylistEpisodes() -> [PlaylistEpisode] {
        upNextManager.allUpNextPlaylistEpisodes(dbQueue: dbQueue)
    }

    public func upNextPlayListContains(episodeUuid: String) -> Bool {
        upNextManager.isEpisodePresent(uuid: episodeUuid, dbQueue: dbQueue)
    }

    public func allUpNextEpisodes() -> [BaseEpisode] {
        let allUpNextEpisodes = upNextManager.allUpNextPlaylistEpisodes(dbQueue: dbQueue)
        if allUpNextEpisodes.count == 0 { return [BaseEpisode]() }

        let episodes = episodeManager.allUpNextEpisodes(dbQueue: dbQueue)
        let userEpisodes = userEpisodeManager.allUpNextEpisodes(dbQueue: dbQueue)

        // this extra step is to make sure we return the episodes in the order they are in the up next list, which they won't be if there's both Episodes and UserEpisodes in Up Next
        if userEpisodes.isEmpty {
            return episodes
        }

        var convertedEpisodes = [BaseEpisode]()
        var episodeIndex = 0
        var userEpisodeIndex = 0
        for upNextEpisode in allUpNextEpisodes {
            if let episode = episodes[safe: episodeIndex],
               episode.uuid == upNextEpisode.episodeUuid {
                convertedEpisodes.append(episode)
                episodeIndex += 1
                continue
            }
            if let userEpisode = userEpisodes[safe: userEpisodeIndex], userEpisode.uuid == upNextEpisode.episodeUuid {
                convertedEpisodes.append(userEpisode)
                userEpisodeIndex += 1
            }
        }

        return convertedEpisodes
    }

    public func allUpNextEpisodeUuids() -> [BaseEpisode] {
        upNextManager.allUpNextPlaylistEpisodes(dbQueue: dbQueue).map {
            let episode = Episode()
            episode.uuid = $0.episodeUuid
            episode.hasOnlyUuid = true
            return episode
        }
    }

    public func findPlaylistEpisode(uuid: String) -> PlaylistEpisode? {
        upNextManager.findPlaylistEpisode(uuid: uuid, dbQueue: dbQueue)
    }

    public func positionForPlaylistEpisode(bottomOfList: Bool) -> Int32 {
        upNextManager.positionForPlaylistEpisode(bottomOfList: bottomOfList, dbQueue: dbQueue)
    }

    public func deleteAllUpNextEpisodes() {
        upNextManager.deleteAllUpNextEpisodes(dbQueue: dbQueue)
    }

    public func deleteAllUpNextEpisodesExcept(episodeUuid: String) {
        upNextManager.deleteAllUpNextEpisodesExcept(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func deleteAllUpNextEpisodesNotIn(uuids: [String]) {
        upNextManager.deleteAllUpNextEpisodesNotIn(uuids: uuids, dbQueue: dbQueue)
    }

    public func deleteAllUpNextEpisodesIn(uuids: [String]) {
        upNextManager.deleteAllUpNextEpisodesIn(uuids: uuids, dbQueue: dbQueue)
    }

    public func save(playlistEpisode: PlaylistEpisode) {
        upNextManager.save(playlistEpisode: playlistEpisode, dbQueue: dbQueue)
    }

    public func save(playlistEpisodes: [PlaylistEpisode]) {
        upNextManager.save(playlistEpisodes: playlistEpisodes, dbQueue: dbQueue)
    }

    public func delete(playlistEpisode: PlaylistEpisode) {
        upNextManager.delete(playlistEpisode: playlistEpisode, dbQueue: dbQueue)
    }

    public func movePlaylistEpisode(from: Int, to: Int) {
        upNextManager.movePlaylistEpisode(from: from, to: to, dbQueue: dbQueue)
    }

    public func playlistEpisodeCount() -> Int {
        upNextManager.playlistEpisodeCount(dbQueue: dbQueue)
    }

    public func playlistEpisodeAt(index: Int) -> PlaylistEpisode? {
        upNextManager.playlistEpisodeAt(index: index, dbQueue: dbQueue)
    }

    public func episodeInUpNextAt(index: Int) -> BaseEpisode? {
        guard let playlistEpisode = playlistEpisodeAt(index: index) else { return nil }

        if let episode = userEpisodeManager.findBy(uuid: playlistEpisode.episodeUuid, dbQueue: dbQueue) {
            return episode
        }

        return episodeManager.findBy(uuid: playlistEpisode.episodeUuid, dbQueue: dbQueue)
    }

    // MARK: - Up Next Changes

    public func findReplaceAction() -> UpNextChanges? {
        upNextChangesManager.findReplaceAction(dbQueue: dbQueue)
    }

    public func findUpdateActions() -> [UpNextChanges] {
        upNextChangesManager.findUpdateActions(dbQueue: dbQueue)
    }

    public func saveUpNextRemove(episodeUuid: String) {
        upNextChangesManager.saveUpNextRemove(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func saveUpNextAddToTop(episodeUuid: String) {
        upNextChangesManager.saveUpNextAddToTop(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func saveUpNextAddToBottom(episodeUuid: String) {
        upNextChangesManager.saveUpNextAddToBottom(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func saveUpNextAddNowPlaying(episodeUuid: String) {
        upNextChangesManager.saveUpNextAddNowPlaying(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func saveReplace(episodeList: [String]) {
        upNextChangesManager.saveReplace(episodeList: episodeList, dbQueue: dbQueue)
    }

    public func deleteChangesOlderThan(utcTime: Int64) {
        upNextChangesManager.deleteChangesOlderThan(utcTime: utcTime, dbQueue: dbQueue)
    }

    // MARK: - Podcasts

    public func allPodcasts(includeUnsubscribed: Bool, reloadFromDatabase: Bool = false) -> [Podcast] {
        podcastManager.allPodcasts(includeUnsubscribed: includeUnsubscribed, reloadFromDatabase: reloadFromDatabase, dbQueue: dbQueue)
    }

    public func allPodcastsOrderedByTitle(reloadFromDatabase: Bool = false) -> [Podcast] {
        podcastManager.allPodcastsOrderedByTitle(reloadFromDatabase: reloadFromDatabase, dbQueue: dbQueue)
    }

    public func allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: Bool = false) -> [Podcast] {
        podcastManager.allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: reloadFromDatabase, dbQueue: dbQueue)
    }

    public func allPodcastsOrderedByAddedDate(reloadFromDatabase: Bool = false) -> [Podcast] {
        podcastManager.allPodcastsOrderedByAddedDate(reloadFromDatabase: reloadFromDatabase, dbQueue: dbQueue)
    }

    public func findPodcast(uuid: String, includeUnsubscribed: Bool = false) -> Podcast? {
        podcastManager.find(uuid: uuid, includeUnsubscribed: includeUnsubscribed, dbQueue: dbQueue)
    }

    public func allUnsubscribedPodcastUuids() -> [String] {
        podcastManager.allUnsubscribedPodcastUuids(dbQueue: dbQueue)
    }

    public func allUnsubscribedPodcasts() -> [Podcast] {
        podcastManager.allUnsubscribedPodcasts(dbQueue: dbQueue)
    }

    public func allPaidPodcasts() -> [Podcast] {
        podcastManager.allPaidPodcasts(dbQueue: dbQueue)
    }

    public func allOverrideGlobalArchivePodcasts() -> [Podcast] {
        podcastManager.allOverrideGlobalArchivePodcasts(dbQueue: dbQueue)
    }

    public func podcastCount() -> Int {
        podcastManager.count(dbQueue: dbQueue)
    }

    public func podcastUnfinishedCounts() -> [String: Int32] {
        podcastManager.unfinishedCounts(dbQueue: dbQueue)
    }

    public func markAllPodcastsSynced() {
        podcastManager.markAllSynced(dbQueue: dbQueue)
    }

    public func markAllPodcastsUnsynced() {
        podcastManager.markAllUnsynced(dbQueue: dbQueue)
    }

    public func markAllPodcastsUnsyncedWhereLastSyncAtNot(_ lastSyncAt: String) {
        podcastManager.markAllUnsyncedWhereLastSyncAtNot(lastSyncAt, dbQueue: dbQueue)
    }

    public func setPushForAllPodcasts(pushEnabled: Bool) {
        podcastManager.setPushForAllPodcasts(pushEnabled: pushEnabled, dbQueue: dbQueue)
    }

    public func saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: Int32) {
        podcastManager.saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: autoAddToUpNext, dbQueue: dbQueue)
    }

    public func updateAutoAddToUpNext(to value: AutoAddToUpNextSetting, for podcasts: [Podcast]) {
        podcastManager.updateAutoAddToUpNext(to: value, for: podcasts, in: dbQueue)
    }

    public func setDownloadSettingForAllPodcasts(setting: AutoDownloadSetting) {
        podcastManager.setDownloadSettingForAllPodcasts(setting: setting, dbQueue: dbQueue)
    }

    public func allUnsyncedPodcasts() -> [Podcast] {
        podcastManager.allUnsynced(dbQueue: dbQueue)
    }

    public func delete(podcast: Podcast) {
        podcastManager.delete(podcast: podcast, dbQueue: dbQueue)
    }

    public func save(podcast: Podcast) {
        podcastManager.save(podcast: podcast, dbQueue: dbQueue)
    }

    public func savePushSetting(podcast: Podcast, pushEnabled: Bool) {
        podcastManager.savePushSetting(podcast: podcast, pushEnabled: pushEnabled, dbQueue: dbQueue)
    }

    public func savePushSetting(podcastUuid: String, pushEnabled: Bool) {
        podcastManager.savePushSetting(podcastUuid: podcastUuid, pushEnabled: pushEnabled, dbQueue: dbQueue)
    }

    public func saveAutoAddToUpNext(podcastUuid: String, autoAddToUpNext: Int32) {
        podcastManager.saveAutoAddToUpNext(podcastUuid: podcastUuid, autoAddToUpNext: autoAddToUpNext, dbQueue: dbQueue)
    }

    public func savePodcastDownloadSetting(_ setting: AutoDownloadSetting, podcastUuid: String) {
        podcastManager.savePodcastDownloadSetting(setting, podcastUuid: podcastUuid, dbQueue: dbQueue)
    }

    public func saveAutoArchiveLimit(podcast: Podcast, limit: Int32) {
        podcastManager.saveAutoArchiveLimit(podcast: podcast, limit: limit, dbQueue: dbQueue)
    }

    public func saveSortOrders(podcasts: [Podcast]) {
        podcastManager.saveSortOrders(podcasts: podcasts, dbQueue: dbQueue)
    }

    public func markAllUnarchivedForPodcast(id: Int64) {
        episodeManager.markAllUnarchivedForPodcast(id: id, dbQueue: dbQueue)
    }

    public func updateAllPodcastGrouping(to grouping: PodcastGrouping) {
        podcastManager.updateAllPodcastGrouping(to: grouping, dbQueue: dbQueue)
    }

    public func updateAllShowArchived(to showArchived: Bool) {
        podcastManager.updateAllShowArchived(to: showArchived, dbQueue: dbQueue)
    }

    public func setPodcastImageVersion(podcastUuid: String, version: Int) {
        podcastManager.setPodcastImageVersion(podcastUuid: podcastUuid, version: version, dbQueue: dbQueue)
    }

    public func setAllPodcastImageVersions(to version: Int) {
        podcastManager.setAllPodcastImageVersions(to: version, dbQueue: dbQueue)
    }

    public func bulkSetFolderUuid(folderUuid: String, podcastUuids: [String]) {
        podcastManager.bulkSetFolderUuid(folderUuid: folderUuid, podcastUuids: podcastUuids, dbQueue: dbQueue)
    }

    public func updatePodcastFolder(podcastUuid: String, to folderUuid: String?, sortOrder: Int32) {
        podcastManager.updatePodcastFolder(podcastUuid: podcastUuid, sortOrder: sortOrder, folderUuid: folderUuid, dbQueue: dbQueue)
    }

    // MARK: - Episodes

    public func findEpisode(uuid: String) -> Episode? {
        episodeManager.findBy(uuid: uuid, dbQueue: dbQueue)
    }

    public func findBaseEpisode(uuid: String) -> BaseEpisode? {
        if let episode = userEpisodeManager.findBy(uuid: uuid, dbQueue: dbQueue) {
            return episode
        }

        return episodeManager.findBy(uuid: uuid, dbQueue: dbQueue)
    }

    public func markAllEpisodePlaybackHistorySynced() {
        episodeManager.markAllEpisodePlaybackHistorySynced(dbQueue: dbQueue)
    }

    public func downloadedEpisodeExists(uuid: String) -> Bool {
        episodeManager.downloadedEpisodeExists(uuid: uuid, dbQueue: dbQueue)
    }

    public func findBaseEpisode(downloadTaskId: String) -> BaseEpisode? {
        if let episode = userEpisodeManager.findBy(downloadTaskId: downloadTaskId, dbQueue: dbQueue) {
            return episode
        }

        return episodeManager.findBy(downloadTaskId: downloadTaskId, dbQueue: dbQueue)
    }

    public func findEpisodeWhere(customWhere: String, arguments: [Any]?) -> Episode? {
        episodeManager.findWhere(customWhere: customWhere, arguments: arguments, dbQueue: dbQueue)
    }

    public func findEpisodesWhereNotNull(propertyName: String) -> [BaseEpisode] {
        var episodes = episodeManager.findWhereNotNull(columnName: propertyName, dbQueue: dbQueue) as [BaseEpisode]
        let userEpisodes = userEpisodeManager.findWhereNotNull(columnName: propertyName, dbQueue: dbQueue) as [BaseEpisode]
        episodes.append(contentsOf: userEpisodes)
        return episodes
    }

    public func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        episodeManager.findEpisodesWhere(customWhere: customWhere, arguments: arguments, dbQueue: dbQueue)
    }

    public func findLatestEpisode(podcast: Podcast) -> Episode? {
        episodeManager.findLatestEpisode(podcast: podcast, dbQueue: dbQueue)
    }

    public func unsyncedEpisodes(limit: Int) -> [Episode] {
        episodeManager.unsyncedEpisodes(limit: limit, dbQueue: dbQueue)
    }

    public func unsyncedUserEpisodes() -> [UserEpisode] {
        userEpisodeManager.unsyncedEpisodes(dbQueue: dbQueue)
    }

    public func episodesWithListenHistory(limit: Int) -> [Episode] {
        episodeManager.episodesWithListenHistory(limit: limit, dbQueue: dbQueue)
    }

    public func findDownloadedEpisodes() -> [BaseEpisode] {
        let query = "episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        let downloadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)

        let downloadedUserEpisodes = userEpisodeManager.findAllDownloaded(sortedBy: .newestToOldest, dbQueue: dbQueue)
        var allEpisodes: [BaseEpisode] = downloadedEpisodes + downloadedUserEpisodes

        allEpisodes.sort(by: { $0.lastDownloadAttemptDate?.compare($1.lastDownloadAttemptDate ?? Date.distantPast) == .orderedDescending })
        return allEpisodes
    }

    public func downloadedEpisodeCount() -> Int {
        let episodeCount = episodeManager.downloadedEpisodeCount(dbQueue: dbQueue)
        let userEpisodeCount = userEpisodeManager.downloadedEpisodeCount(dbQueue: dbQueue)
        return episodeCount + userEpisodeCount
    }

    public func save(episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.save(episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.save(episode: episode, dbQueue: dbQueue)
        }
    }

    public func bulkSave(episodes: [Episode]) {
        episodeManager.bulkSave(episodes: episodes, dbQueue: dbQueue)
    }

    public func bulkSetStarred(starred: Bool, episodes: [Episode], updateSyncStatus: Bool) {
        episodeManager.bulkSetStarred(starred: starred, episodes: episodes, updateSyncFlag: updateSyncStatus, dbQueue: dbQueue)
    }

    public func bulkUserFileDelete(baseEpisodes: [BaseEpisode]) {
        let episodes = baseEpisodes.compactMap { $0 as? Episode }
        if episodes.count > 0 {
            episodeManager.bulkUserFileDelete(episodes: episodes, dbQueue: dbQueue)
        }
        let userEpisodes = baseEpisodes.compactMap { $0 as? UserEpisode }
        if userEpisodes.count > 0 {
            userEpisodeManager.bulkUserFileDelete(episodes: userEpisodes, dbQueue: dbQueue)
        }
    }

    // returns true if the save succeeded, false otherwise
    public func saveIfNotModified(starred: Bool, episodeUuid: String) -> Bool {
        episodeManager.saveIfNotModified(starred: starred, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    // returns true if the save succeeded, false otherwise
    public func saveIfNotModified(archived: Bool, episodeUuid: String) -> Bool {
        episodeManager.saveIfNotModified(archived: archived, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    // returns true if the save succeeded, false otherwise
    public func saveIfNotModified(playingStatus: PlayingStatus, episodeUuid: String) -> Bool {
        episodeManager.saveIfNotModified(playingStatus: playingStatus, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    // returns true if the save succeeded, false otherwise
    @discardableResult
    public func saveIfNotModified(chapters: String, remoteModified: Int64, episodeUuid: String) -> Bool {
        episodeManager.saveIfNotModified(chapters: chapters, remoteModified: remoteModified, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func saveEpisode(playedUpTo: Double, episode: BaseEpisode, updateSyncFlag: Bool) {
        let trace = TraceManager.shared.beginTracing(eventName: "DATABASE_EPISODE_POSITION_SAVE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        if let episode = episode as? Episode {
            episodeManager.saveEpisode(playedUpTo: playedUpTo, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(playedUpTo: playedUpTo, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(playingStatus: PlayingStatus, episode: BaseEpisode, updateSyncFlag: Bool) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(playingStatus: playingStatus, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(playingStatus: playingStatus, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(archived: Bool, episode: Episode, updateSyncFlag: Bool) {
        episodeManager.saveEpisode(archived: archived, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func saveEpisode(excludeFromEpisodeLimit: Bool, episode: Episode) {
        episodeManager.saveEpisode(excludeFromEpisodeLimit: excludeFromEpisodeLimit, episode: episode, dbQueue: dbQueue)
    }

    public func saveEpisode(fileType: String, episode: Episode) {
        episodeManager.saveFileType(episode: episode, fileType: fileType, dbQueue: dbQueue)
    }

    public func saveEpisode(fileSize: Int64, episode: Episode) {
        episodeManager.saveFileSize(episode: episode, fileSize: fileSize, dbQueue: dbQueue)
    }

    public func saveBulkEpisodeSyncInfo(episodes: [EpisodeBasicData]) {
        episodeManager.saveBulkEpisodeSyncInfo(episodes: episodes, dbQueue: dbQueue)
    }

    public func saveFrameCount(episode: BaseEpisode, frameCount: Int64) {
        if let episode = episode as? Episode {
            episodeManager.saveFrameCount(episodeId: episode.id, frameCount: frameCount, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveFrameCount(episodeId: episode.id, frameCount: frameCount, dbQueue: dbQueue)
        }
    }

    public func findFrameCount(episode: BaseEpisode) -> Int64 {
        if let episode = episode as? Episode {
            return episodeManager.findFrameCount(episodeId: episode.id, dbQueue: dbQueue)
        }

        let userEpisode = episode as! UserEpisode
        return userEpisodeManager.findFrameCount(episodeId: userEpisode.id, dbQueue: dbQueue)
    }

    public func saveEpisode(starred: Bool, starredModified: Int64? = nil, episode: Episode, updateSyncFlag: Bool) {
        episodeManager.saveEpisode(starred: starred, starredModified: starredModified, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func saveEpisode(duration: Double, episode: BaseEpisode, updateSyncFlag: Bool) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(duration: duration, episode: episode, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(duration: duration, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(playbackError: String?, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(playbackError: playbackError, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(playbackError: playbackError, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadStatus: DownloadStatus, episode: Episode) {
        episodeManager.saveEpisode(downloadStatus: downloadStatus, episode: episode, dbQueue: dbQueue)
    }

    public func saveEpisode(downloadStatus: DownloadStatus, lastDownloadAttemptDate: Date, autoDownloadStatus: AutoDownloadStatus, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(downloadStatus: downloadStatus, lastDownloadAttemptDate: lastDownloadAttemptDate, autoDownloadStatus: autoDownloadStatus, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(downloadStatus: downloadStatus, lastDownloadAttemptDate: lastDownloadAttemptDate, autoDownloadStatus: autoDownloadStatus, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadStatus: DownloadStatus, downloadError: String?, downloadTaskId: String?, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(downloadStatus: downloadStatus, downloadError: downloadError, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(downloadStatus: downloadStatus, downloadError: downloadError, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(autoDownloadStatus: AutoDownloadStatus, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(autoDownloadStatus: autoDownloadStatus, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(autoDownloadStatus: autoDownloadStatus, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadStatus: DownloadStatus, downloadTaskId: String?, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(downloadStatus: downloadStatus, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(downloadStatus: downloadStatus, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, downloadTaskId: String?, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(downloadStatus: downloadStatus, sizeInBytes: sizeInBytes, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(downloadStatus: downloadStatus, sizeInBytes: sizeInBytes, downloadTaskId: downloadTaskId, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadStatus: DownloadStatus, sizeInBytes: Int64, episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.saveEpisode(downloadStatus: downloadStatus, sizeInBytes: sizeInBytes, episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.saveEpisode(downloadStatus: downloadStatus, sizeInBytes: sizeInBytes, episode: episode, dbQueue: dbQueue)
        }
    }

    public func saveEpisode(downloadUrl: String, episodeUuid: String) {
        episodeManager.saveEpisode(downloadUrl: downloadUrl, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func updateEpisodePlaybackInteractionDate(episode: BaseEpisode) {
        // only Episodes have playback interaction dates, we don't have those for UserEpisodes
        if let episode = episode as? Episode {
            episodeManager.updateEpisodePlaybackInteractionDate(episode: episode, dbQueue: dbQueue)
        }
    }

    public func setEpisodePlaybackInteractionDate(interactionDate: Date, episodeUuid: String) {
        episodeManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func clearKeepEpisodeModified(episode: Episode) {
        episodeManager.clearKeepEpisodeModified(episode: episode, dbQueue: dbQueue)
    }

    public func clearEpisodePlaybackInteractionDate(episodeUuid: String) {
        episodeManager.clearEpisodePlaybackInteractionDate(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func clearEpisodePlaybackInteractionDatesBefore(date: Date) {
        episodeManager.clearEpisodePlaybackInteractionDatesBefore(date: date, dbQueue: dbQueue)
    }

    public func clearAllEpisodePlayInteractions() {
        episodeManager.clearAllEpisodePlaybackInteractions(dbQueue: dbQueue)
    }

    public func clearDownloadTaskId(episode: BaseEpisode) {
        if let episode = episode as? Episode {
            episodeManager.clearDownloadTaskId(episode: episode, dbQueue: dbQueue)
        } else if let episode = episode as? UserEpisode {
            userEpisodeManager.clearDownloadTaskId(episode: episode, dbQueue: dbQueue)
        }
    }

    public func bulkMarkAsPlayed(episodes: [Episode], updateSyncFlag: Bool) {
        episodeManager.bulkMarkAsPlayed(episodes: episodes, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func bulkMarkAsPlayed(episodes: [UserEpisode], updateSyncFlag: Bool) {
        userEpisodeManager.bulkMarkAsPlayed(episodes: episodes, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func bulkMarkAsUnPlayed(baseEpisodes: [BaseEpisode], updateSyncFlag: Bool) {
        let episodes = baseEpisodes.compactMap { $0 as? Episode }
        if episodes.count > 0 {
            episodeManager.bulkMarkAsUnPlayed(episodes: episodes, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        }

        let userEpisodes = baseEpisodes.compactMap { $0 as? UserEpisode }
        if userEpisodes.count > 0 {
            userEpisodeManager.bulkMarkAsUnPlayed(episodes: userEpisodes, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
        }
    }

    public func bulkArchive(episodes: [Episode], markAsNotDownloaded: Bool, markAsPlayed: Bool, updateSyncFlag: Bool) {
        episodeManager.bulkArchive(episodes: episodes, markAsNotDownloaded: markAsNotDownloaded, markAsPlayed: markAsPlayed, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func bulkUnarchive(episodes: [Episode], updateSyncFlag: Bool) {
        episodeManager.bulkUnarchive(episodes: episodes, updateSyncFlag: updateSyncFlag, dbQueue: dbQueue)
    }

    public func markAllSynced(episodes: [Episode]) {
        episodeManager.markAllSynced(episodes: episodes, dbQueue: dbQueue)
    }

    public func allEpisodesForPodcast(id: Int64) -> [Episode] {
        episodeManager.allEpisodesForPodcast(id: id, dbQueue: dbQueue)
    }

    public func delete(episodeUuid: String) {
        episodeManager.delete(episodeUuid: episodeUuid, dbQueue: dbQueue)
    }

    public func deleteAllEpisodesInPodcast(podcastId: Int64) {
        episodeManager.deleteAllEpisodesInPodcast(podcastId: podcastId, dbQueue: dbQueue)
    }

    public func randomPodcasts() -> [Podcast] {
        podcastManager.randomPodcasts(dbQueue: dbQueue)
    }

    // MARK: - User Episodes

    public func findUserEpisode(uuid: String) -> UserEpisode? {
        userEpisodeManager.findBy(uuid: uuid, dbQueue: dbQueue)
    }

    public func allUserEpisodes(sortedBy: UploadedSort, limit: Int? = nil) -> [UserEpisode] {
        userEpisodeManager.findAll(sortedBy: sortedBy, limit: limit, dbQueue: dbQueue)
    }

    public func allUserEpisodesDownloaded(sortedBy: UploadedSort, limit: Int? = nil) -> [UserEpisode] {
        userEpisodeManager.findAllDownloaded(sortedBy: sortedBy, limit: limit, dbQueue: dbQueue)
    }

    public func allUserEpisodesUploaded() -> [UserEpisode] {
        userEpisodeManager.findAllWithUploadStatus(.uploaded, dbQueue: dbQueue)
    }

    public func bulkSave(episodes: [UserEpisode]) {
        userEpisodeManager.bulkSave(episodes: episodes, dbQueue: dbQueue)
    }

    public func delete(userEpisodeUuid: String) {
        userEpisodeManager.delete(userEpisodeUuid: userEpisodeUuid, dbQueue: dbQueue)
    }

    public func deleteUserEpisodes(userEpisodeUuids: [String]) {
        userEpisodeManager.delete(userEpisodeUuids: userEpisodeUuids, dbQueue: dbQueue)
    }

    public func saveEpisode(uploadStatus: UploadStatus, episode: UserEpisode) {
        userEpisodeManager.saveEpisode(uploadStatus: uploadStatus, episode: episode, dbQueue: dbQueue)
    }

    public func saveEpisode(uploadStatus: UploadStatus, uploadTaskId: String?, episode: UserEpisode) {
        userEpisodeManager.saveEpisode(uploadStatus: uploadStatus, uploadTaskId: uploadTaskId, episode: episode, dbQueue: dbQueue)
    }

    public func saveEpisode(uploadStatus: UploadStatus, uploadError: String?, uploadTaskId: String?, episode: UserEpisode) {
        userEpisodeManager.saveEpisode(uploadStatus: uploadStatus, uploadError: uploadError, uploadTaskId: uploadTaskId, episode: episode, dbQueue: dbQueue)
    }

    public func clearUploadTaskId(episode: UserEpisode) {
        userEpisodeManager.clearUploadTaskId(episode: episode, dbQueue: dbQueue)
    }

    public func findUserEpisode(uploadTaskId: String) -> UserEpisode? {
        userEpisodeManager.findBy(uploadTaskId: uploadTaskId, dbQueue: dbQueue)
    }

    public func findUserEpisodesWithUploadStatus(_ status: UploadStatus) -> [UserEpisode] {
        userEpisodeManager.findAllWithUploadStatus(status, dbQueue: dbQueue)
    }

    public func findUserEpisodesWhereNotNull(propertyName: String) -> [UserEpisode] {
        userEpisodeManager.findWhereNotNull(columnName: propertyName, dbQueue: dbQueue)
    }

    public func markImageUploaded(episode: UserEpisode) {
        userEpisodeManager.markEpisodeImageUploaded(episode: episode, dbQueue: dbQueue)
    }

    public func removeOrphanedUserEpisodes() {
        userEpisodeManager.removeOrphaned(dbQueue: dbQueue)
    }

    // MARK: - Filters

    public func allFilters(includeDeleted: Bool) -> [EpisodeFilter] {
        filterManager.allFilters(includeDeleted: includeDeleted, dbQueue: dbQueue)
    }

    public func filterCount(includeDeleted: Bool) -> Int {
        filterManager.count(includeDeleted: includeDeleted, dbQueue: dbQueue)
    }

    public func findFilter(uuid: String) -> EpisodeFilter? {
        filterManager.findBy(uuid: uuid, dbQueue: dbQueue)
    }

    public func episodeCount(forFilter: EpisodeFilter, episodeUuidToAdd: String?) -> Int {
        filterManager.episodeCount(forFilter: forFilter, episodeUuidToAdd: episodeUuidToAdd, dbQueue: dbQueue)
    }

    public func deleteDeletedFilters() {
        filterManager.deleteDeletedFilters(dbQueue: dbQueue)
    }

    public func allUnsyncedFilters() -> [EpisodeFilter] {
        filterManager.allUnsyncedFilters(dbQueue: dbQueue)
    }

    public func save(filter: EpisodeFilter) {
        filterManager.save(filter: filter, dbQueue: dbQueue)
    }

    public func delete(filter: EpisodeFilter) {
        filterManager.delete(filter: filter, dbQueue: dbQueue)
    }

    public func markAllEpisodeFiltersSynced() {
        filterManager.markAllSynced(dbQueue: dbQueue)
    }

    public func markAllEpisodeFiltersUnsynced() {
        filterManager.markAllUnsynced(dbQueue: dbQueue)
    }

    public func nextSortPositionForFilter() -> Int {
        filterManager.nextSortPositionForFilter(dbQueue: dbQueue)
    }

    public func updatePosition(filter: EpisodeFilter, newPosition: Int32) {
        filterManager.updatePosition(filter: filter, newPosition: newPosition, dbQueue: dbQueue)
    }

    // MARK: - Folders

    public func save(folder: Folder) {
        folderManager.save(folder: folder, dbQueue: dbQueue)
    }

    public func allFolders(includeDeleted: Bool = false) -> [Folder] {
        folderManager.allFolders(includeDeleted: includeDeleted, dbQueue: dbQueue)
    }

    public func findFolder(uuid: String) -> Folder? {
        folderManager.findFolder(uuid: uuid, dbQueue: dbQueue)
    }

    public func allPodcastsInFolder(folder: Folder) -> [Podcast] {
        podcastManager.allPodcastsInFolder(folder: folder, dbQueue: dbQueue)
    }

    public func countOfPodcastsInFolder(folder: Folder) -> Int {
        podcastManager.countOfPodcastsInFolder(folder: folder, dbQueue: dbQueue)
    }

    public func countOfPodcastsInRootFolder() -> Int {
        podcastManager.countOfPodcastsInFolder(folder: nil, dbQueue: dbQueue)
    }

    public func saveSortOrders(folders: [Folder], syncModified: Int64) {
        folderManager.saveSortOrders(folders: folders, syncModified: syncModified, dbQueue: dbQueue)
    }

    public func updateFolderColor(folderUuid: String, color: Int32, syncModified: Int64) {
        folderManager.updateFolderColor(folderUuid: folderUuid, color: color, syncModified: syncModified, dbQueue: dbQueue)
    }

    public func updateFolderSyncModified(folderUuid: String, syncModified: Int64) {
        folderManager.updateFolderSyncModified(folderUuid: folderUuid, syncModified: syncModified, dbQueue: dbQueue)
    }

    public func delete(folderUuid: String, markAsDeleted: Bool) {
        podcastManager.removeAllPodcastsFromFolder(folderUuid: folderUuid, dbQueue: dbQueue)

        if markAsDeleted {
            folderManager.markFolderAsDeleted(folderUuid: folderUuid, syncModified: TimeFormatter.currentUTCTimeInMillis(), dbQueue: dbQueue)
        } else {
            folderManager.delete(folderUuid: folderUuid, dbQueue: dbQueue)
        }
    }

    public func bulkSetSyncModified(_ syncModified: Int64, onFolders folderUuids: [String]) {
        folderManager.bulkSetSyncModified(syncModified, onFolders: folderUuids, dbQueue: dbQueue)
    }

    public func allUnsyncedFolders() -> [Folder] {
        folderManager.allUnsyncedFolders(dbQueue: dbQueue)
    }

    public func markAllFoldersSynced() {
        folderManager.markAllFoldersSynced(dbQueue: dbQueue)
    }

    public func clearAllFolderInformation() {
        podcastManager.removeAllPodcastsFromAllFolders(dbQueue: dbQueue)
        folderManager.deleteAllFolders(dbQueue: dbQueue)
    }

    // MARK: - Advanced

    public func count(query: String, values: [Any]?) -> Int {
        var count = 0
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery(query, values: values)
                if resultSet.next() {
                    count = resultSet.long(forColumnIndex: 0)
                }
                resultSet.close()
            } catch {}
        }

        return count
    }

    // MARK: - Path Related

    public static func pathToDb() -> String {
        let folderPath = pathToDbFolder() as NSString

        return folderPath.appendingPathComponent("podcast_newDB.sqlite3")
    }

    private static func pathToDbFolder() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        let mainFolder = documentsPath?.appendingPathComponent("Pocket Casts")

        return mainFolder!
    }

    private static func ensureDbFolderExists() {
        do {
            try FileManager.default.createDirectory(atPath: pathToDbFolder(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Unable to create database folder")
        }
    }

    // MARK: - Push Notification

    public func setPushDefaultForNewPodcast(_ podcast: Podcast) {
        // if all the podcasts the user currently has are auto download, set this one to be as well
        let pushOnQuery = "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE subscribed = 1 AND pushEnabled = 1"
        let totalQuery = "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE subscribed = 1"

        let pushOnCount = DataManager.sharedManager.count(query: pushOnQuery, values: nil)
        let totalCount = (DataManager.sharedManager.count(query: totalQuery, values: nil) - 1) // -1 because the podcast we're currently adding could be returned by this query
        if totalCount > 0, pushOnCount >= totalCount {
            podcast.pushEnabled = true
        } else {
            podcast.pushEnabled = false
        }

        DataManager.sharedManager.save(podcast: podcast)
    }
}

// MARK: - Ghost Episode Cleanup

public extension DataManager {
    func findGhostEpisodes() -> [Episode] {
        episodeManager.findGhostEpisodes(dbQueue)
    }

    func deleteGhostsEpisodes(uuids: [String]) {
        dbQueue.inDatabase { db in
            let query = "DELETE FROM \(Self.episodeTableName) WHERE uuid IN (\(uuids.joined(separator: ",")))"

            try? db.executeUpdate(query, values: nil)
        }
    }
}

// MARK: - End of Year stats

public extension DataManager {
    func isEligibleForEndOfYearStories() -> Bool {
        endOfYearManager.isEligible(dbQueue: dbQueue)
    }

    func isFullListeningHistory() -> Bool {
        endOfYearManager.isFullListeningHistory(dbQueue: dbQueue)
    }

    func numberOfEpisodes(year: Int32) -> Int {
        endOfYearManager.numberOfEpisodes(year: year, dbQueue: dbQueue)
    }

    func listeningTime() -> Double? {
        endOfYearManager.listeningTime(dbQueue: dbQueue)
    }

    func listenedCategories() -> [ListenedCategory] {
        endOfYearManager.listenedCategories(dbQueue: dbQueue)
    }

    func listenedNumbers() -> ListenedNumbers {
        endOfYearManager.listenedNumbers(dbQueue: dbQueue)
    }

    func topPodcasts(limit: Int = 5) -> [TopPodcast] {
        endOfYearManager.topPodcasts(dbQueue: dbQueue, limit: limit)
    }

    func longestEpisode() -> Episode? {
        endOfYearManager.longestEpisode(dbQueue: dbQueue)
    }

    func episodesThatExist(year: Int32, uuids: [String]) -> [String] {
        endOfYearManager.episodesThatExist(year: year, dbQueue: dbQueue, uuids: uuids)
    }

    func yearOverYearListeningTime() -> YearOverYearListeningTime {
        endOfYearManager.yearOverYearListeningTime(dbQueue: dbQueue)
    }

    func episodesStartedAndCompleted() -> EpisodesStartedAndCompleted {
        endOfYearManager.episodesStartedAndCompleted(dbQueue: dbQueue)
    }
}
