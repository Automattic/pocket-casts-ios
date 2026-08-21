import Foundation
import SwiftProtobuf
import PocketCastsDataModel
import PocketCastsUtils

class SyncTask: ApiBaseTask, @unchecked Sendable {
    private static let processDataLock = AsyncLock()

    lazy var importQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5

        return queue
    }()

    var totalToImport = 0
    var upToPodcast = 0

    var status = UpdateStatus.notStarted

    private lazy var legacyLastModifiedFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTime, .withFractionalSeconds]

        return formatter
    }()

    private lazy var evenMoreLegacyLastModifiedFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTime]

        return formatter
    }()

    override func apiTokenAcquired(token: String) async {
        await performSync(token: token)
    }

    override func apiTokenAcquisitionFailed() {
        status = .failed
    }

    func incrementalSyncRequest(token: String) -> URLRequest? {
        guard let lastServerModified = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.lastModifiedServerDate), !lastServerModified.isEmpty, let url = URL(string: ServerConstants.Urls.api() + "user/sync/update") else {
            return nil
        }

        let episodesToSync = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)
        guard let dataToSend = createIncrementalSyncData(episodesToSync: episodesToSync) else { return nil }

        var request = createRequest(url: url, method: "POST", token: token)
        request.httpBody = dataToSend

        return request
    }

    private func performSync(token: String) async {
        if let lastServerModified = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.lastModifiedServerDate), !lastServerModified.isEmpty {
            if ServerSettings.homeGridNeedsRefresh() {
                await performHomeGridRefresh()
            }

            await performIncrementalSync(token: token)
        } else {
            await performFullSync(token: token)
        }
    }

    private func performHomeGridRefresh() async {
        FileLog.shared.addMessage("Performing home grid refresh")
        let retrievePodcastsTask = RetrievePodcastsTask()

        retrievePodcastsTask.completion = { podcasts, folders, success in
            if !success {
                FileLog.shared.addMessage("Home grid refresh failed")
                return
            }

            if let folders {
                for folder in folders {
                    FolderHelper.addFolderToDatabase(folder)
                }
            }

            // then update the podcasts with folder info as well as addedDate if required
            if let podcasts {
                // If the server returns ALL `sortPosition` as `0`
                // It means we should keep the local order for them to be synced later
                let serverReturnsSortPosition: Bool = podcasts.compactMap { $0.sortPosition }.map { Int($0) }.reduce(0, +) > 0

                for podcast in podcasts {
                    guard let uuid = podcast.uuid, let localPodcast = DataManager.sharedManager.findPodcast(uuid: uuid) else { continue }

                    // If server's folderUuid is `nil` then we don't change
                    if podcast.folderUuid?.isEmpty == false {
                        localPodcast.folderUuid = podcast.folderUuid
                    }

                    // if the added date from the server is older than the one we have, replace it
                    if let addedDate = podcast.dateAdded, addedDate.timeIntervalSince1970 < localPodcast.addedDate?.timeIntervalSince1970 ?? 0 {
                        localPodcast.addedDate = addedDate
                    }
                    if let sortOrder = podcast.sortPosition, serverReturnsSortPosition {
                        localPodcast.sortOrder = sortOrder
                    }

                    // mark podcast as unsynced so that if our addedDate or sortOrder was preserved that gets sent to the server
                    localPodcast.syncStatus = SyncStatus.notSynced.rawValue

                    DataManager.sharedManager.save(podcast: localPodcast)
                }
            }

            ServerSettings.setHomeGridNeedsRefresh(false)
        }
        await retrievePodcastsTask.runTask()
    }

    private func performFullSync(token: String) async {
        FileLog.shared.addMessage("Performing initial full sync")

        // grab the last sync date before we begin
        let retrieveLastSyncTask = RetrieveLastSyncDateTask()
        var lastSyncAt: String?
        retrieveLastSyncTask.completion = { lastSync in
            lastSyncAt = lastSync
        }
        await retrieveLastSyncTask.runTask()
        guard let lastSyncDate = lastSyncAt else {
            status = .failed
            return
        }

        FileLog.shared.addMessage("Last sync at is \(lastSyncDate)")

        // in a full sync we first ask for all the users podcasts
        let retrievePodcastsTask = RetrievePodcastsTask()
        var podcastRetrieveCallSucceeded = false
        var podcastsToProcess: (podcasts: [PodcastSyncInfo]?, folders: [FolderSyncInfo]?)?
        retrievePodcastsTask.completion = { podcasts, folders, success in
            podcastRetrieveCallSucceeded = success

            if success {
                podcastsToProcess = (podcasts, folders)
            }
        }
        await retrievePodcastsTask.runTask()

        if let podcastsToProcess {
            await processServerHomeGrid(podcasts: podcastsToProcess.podcasts, folders: podcastsToProcess.folders, lastSyncAt: lastSyncDate)
        }

        if !podcastRetrieveCallSucceeded {
            status = .failed
            return
        }

        // next we need their playlists
        let retrievePlaylistsTask = RetrievePlaylistsTask()
        retrievePlaylistsTask.completion = { playlists in
            guard let playlists else { return }

            self.processServerPlaylists(playlists)
        }
        await retrievePlaylistsTask.runTask()

        // Retrieve all the bookmarks
        var bookmarksToProcess: [Api_BookmarkResponse]?
        await RetrieveBookmarksTask { bookmarks in
            bookmarksToProcess = bookmarks
        }.runTask()

        if let bookmarksToProcess {
            await processServerBookmarks(bookmarksToProcess)
        }

        UserDefaults.standard.set(lastSyncDate, forKey: ServerConstants.UserDefaults.lastModifiedServerDate)

        status = .successNewData
    }

    private func performIncrementalSync(token: String) async {
        if isCancelled {
            status = .cancelled
            return
        }

        let trace = TraceManager.shared.beginTracing(eventName: "SERVER_INCREMENTAL_SYNC")
        defer { TraceManager.shared.endTracing(trace: trace) }

        let episodesToSync = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)
        guard let dataToSend = createIncrementalSyncData(episodesToSync: episodesToSync) else { return }
        if isCancelled {
            status = .cancelled
            return
        }

        let url = ServerConstants.Urls.api() + "user/sync/update"
        let (data, httpStatus) = await postToServer(url: url, token: token, data: dataToSend)
        status = await processSyncData(data, httpStatus: httpStatus, episodesToSync: episodesToSync)
        if status == .failed {
            ServerNotificationsHelper.shared.fireSyncFailed()
            return
        }

        status = .success
    }

    func processSyncData(_ data: Data?, httpStatus: Int, episodesToSync: [Episode]) async -> UpdateStatus {
        guard let responseData = data, httpStatus == ServerConstants.HttpConstants.ok else {
            FileLog.shared.addMessage("SyncTask: syncing failed with status \(httpStatus)")

            return .failed
        }

        // ensure that only one sync can be processing data at once. The code below isn't thread safe, and will lead to potential issues otherwise
        await SyncTask.processDataLock.lock()
        let status = await process(responseData: responseData)
        await SyncTask.processDataLock.unlock()

        return status
    }

    private func process(responseData: Data) async -> UpdateStatus {
        do {
            DataManager.sharedManager.markAllPodcastsSynced()
            DataManager.sharedManager.markAllPlaylistsSynced()
            DataManager.sharedManager.markAllFoldersSynced()

            Task {
                await dataManager.bookmarks.markAllBookmarksAsSynced()
            }

            let response = try Api_SyncUpdateResponse(serializedBytes: responseData)
            await processServerData(response: response)

            StatsManager.shared.setSyncStatus(.synced)

            UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastSyncTime)
            if response.lastModified > 0 {
                UserDefaults.standard.set("\(response.lastModified)", forKey: ServerConstants.UserDefaults.lastModifiedServerDate)
            }
            UserDefaults.standard.synchronize()

            return .success
        } catch {
            FileLog.shared.addMessage("SyncTask: syncing failed due to exception \(error.localizedDescription)")
            ServerNotificationsHelper.shared.fireSyncFailed()
        }

        return .failed
    }

    private func createIncrementalSyncData(episodesToSync: [Episode]) -> Data? {
        var records = [Api_Record]()
        if let podcastChanges = changedPodcasts() {
            records += podcastChanges
        }
        if let episodeChanges = changedEpisodes(for: episodesToSync) {
            records += episodeChanges
        }
        if let filterChanges = changedPlaylists() {
            records += filterChanges
        }
        if let folderChanges = changedFolders() {
            records += folderChanges
        }
        if let statsChanges = changedStats() {
            records.append(statsChanges)
        }

        if let bookmarks = changedBookmarks() {
            records += bookmarks
            FileLog.shared.addMessage("SyncTask: Number of changed bookmarks: \(bookmarks.count)")
        }

        FileLog.shared.addMessage("SyncTask: sending \(records.count) changed items to the server")

        do {
            var syncRequest = Api_SyncUpdateRequest()
            syncRequest.records = records
            if let lastModifiedStr = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.lastModifiedServerDate) {
                if let lastModified = Int64(lastModifiedStr) {
                    syncRequest.lastModified = lastModified
                }
                // previously the server was sending in a last modified two formats "2019-10-02T00:26:35.375Z" and "2019-10-02T00:26:35Z"
                // we attempt to handle both below
                else if let date = evenMoreLegacyLastModifiedFormatter.date(from: lastModifiedStr) {
                    let utcMillis = date.timeIntervalSince1970 * 1000
                    syncRequest.lastModified = Int64(utcMillis)
                } else if let date = legacyLastModifiedFormatter.date(from: lastModifiedStr) {
                    let utcMillis = date.timeIntervalSince1970 * 1000
                    syncRequest.lastModified = Int64(utcMillis)
                }
            }
            syncRequest.deviceUtcTimeMs = TimeFormatter.currentUTCTimeInMillis()
            if let country = Locale.current.region?.identifier {
                syncRequest.country = country
            }
            syncRequest.deviceID = ServerConfig.shared.syncDelegate?.uniqueAppId() ?? ""
            syncRequest.deviceType = Google_Protobuf_Int32Value(ServerConstants.Values.deviceTypeiOS)

            return try syncRequest.serializedData()
        } catch {}

        return nil
    }
}
