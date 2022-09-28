import DataModel
import Foundation
import Utils

class SyncTask: ApiBaseTask {
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

    override func apiTokenAcquired(token: String) {
        performSync(token: token)
    }

    override func apiTokenAcquisitionFailed() {
        status = .failed
    }

    private func performSync(token: String) {
        if let lastServerModified = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastModifiedServerDate), lastServerModified.count > 0 {
            performIncrementalSync(token: token)
        } else {
            performFullSync(token: token)
        }
    }

    private func performFullSync(token: String) {
        // grab the last sync date before we begin
        let retrieveLastSyncTask = RetrieveLastSyncDateTask()
        var lastSyncAt: String?
        retrieveLastSyncTask.completion = { lastSync in
            lastSyncAt = lastSync
        }
        retrieveLastSyncTask.runTaskSynchronously()
        guard let lastSyncDate = lastSyncAt else {
            status = .failed
            return
        }

        // in a full sync we first ask for all the users podcasts
        let retrievePodcastsTask = RetrievePodcastsTask()
        retrievePodcastsTask.completion = { podcasts in
            guard let podcasts = podcasts else { return }

            self.processServerPodcasts(podcasts)
        }
        retrievePodcastsTask.runTaskSynchronously()

        // next we need their filters
        let retrieveFiltersTask = RetrieveFiltersTask()
        retrieveFiltersTask.completion = { filters in
            guard let filters = filters else { return }

            self.processServerFilters(filters)
        }
        retrieveFiltersTask.runTaskSynchronously()

        UserDefaults.standard.set(lastSyncDate, forKey: Constants.UserDefaults.lastModifiedServerDate)

        status = .successNewData
    }

    private func performIncrementalSync(token: String) {
        if isCancelled {
            status = .cancelled
            return
        }

        var records = [Api_Record]()
        if let podcastChanges = changedPodcasts() {
            records = records + podcastChanges
        }

        let episodesToSync = DataManager.sharedManager.unsyncedEpisodes(limit: Constants.Limits.maxEpisodesToSync)
        if let episodeChanges = changedEpisodes(for: episodesToSync) {
            records = records + episodeChanges
        }
        if let filterChanges = changedFilters() {
            records = records + filterChanges
        }
        if let statsChanges = changedStats() {
            records.append(statsChanges)
        }

        do {
            var syncRequest = Api_SyncUpdateRequest()
            syncRequest.records = records
            if let lastModifiedStr = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastModifiedServerDate) {
                if let lastModified = Int64(lastModifiedStr) {
                    syncRequest.lastModified = lastModified
                }
                // previously the server was sending in a last modified two formats "2019-10-02T00:26:35.375Z" and "2019-10-02T00:26:35Z"
                // we attempt to handle both below
                else if let date = evenMoreLegacyLastModifiedFormatter.date(from: lastModifiedStr) {
                    let utcMillis = date.timeIntervalSince1970 * 1000
                    syncRequest.lastModified = Int64(utcMillis)
                } else if #available(iOS 12, *) {
                    // the property withFractionalSeconds is documented as being available in iOS 11, but it's not, it's iOS 12+ only and will crash if you use it
                    if let date = legacyLastModifiedFormatter.date(from: lastModifiedStr) {
                        let utcMillis = date.timeIntervalSince1970 * 1000
                        syncRequest.lastModified = Int64(utcMillis)
                    }
                }
            }
            syncRequest.deviceUtcTimeMs = TimeFormatter.currentUTCTimeInMillis()
            if let country = Locale.current.regionCode {
                syncRequest.country = country
            }
            if let deviceId = Settings.uniqueAppId() {
                syncRequest.deviceID = deviceId
            }

            let dataToSend = try syncRequest.serializedData()

            if isCancelled {
                status = .cancelled
                return
            }

            let url = Server.Urls.api + "user/sync/update"
            let (data, httpStatus) = postToServer(url: url, token: token, data: dataToSend)
            guard let responseData = data, httpStatus == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("SyncTask: syncing failed with status \(httpStatus)")

                status = .failed
                NotificationsHelper.shared.fireSyncFailed()

                return
            }

            DataManager.sharedManager.markAllPodcastsSynced()
            DataManager.sharedManager.markAllSynced(episodes: episodesToSync)
            DataManager.sharedManager.markAllEpisodeFiltersSynced()

            let response = try Api_SyncUpdateResponse(serializedData: responseData)
            processServerData(response: response)

            StatsManager.shared.setSyncStatus(.synced)

            UserDefaults.standard.set(Date(), forKey: Constants.UserDefaults.lastSyncTime)
            if response.lastModified > 0 {
                UserDefaults.standard.set("\(response.lastModified)", forKey: Constants.UserDefaults.lastModifiedServerDate)
            }
            UserDefaults.standard.synchronize()

            status = .success
        } catch {
            FileLog.shared.addMessage("SyncTask: syncing failed due to exception \(error.localizedDescription)")
            NotificationsHelper.shared.fireSyncFailed()
            status = .failed
        }
    }
}
