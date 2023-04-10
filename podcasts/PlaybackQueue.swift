import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PlaybackQueue: NSObject {
    // we get asked for this a lot, so might as well cache it
    private var topEpisode: BaseEpisode?

    private let syncTimerDelay: TimeInterval = 5
    private var syncTimer: Timer?

    // MARK: - Editing

    func remove(episode: BaseEpisode, fireNotification: Bool) {
        guard let episodeToRemove = DataManager.sharedManager.findPlaylistEpisode(uuid: episode.uuid) else { return }

        FileLog.shared.addMessage("PlaybackQueue: removing \(episode.title ?? "Untitled") episode")
        DataManager.sharedManager.delete(playlistEpisode: episodeToRemove)
        if SyncManager.isUserLoggedIn() {
            DataManager.sharedManager.saveUpNextRemove(episodeUuid: episode.uuid)
            startSyncTimer()
        }

        refreshAppFiring(notificationName: fireNotification ? Constants.Notifications.upNextEpisodeRemoved : nil, notificationObject: episode.uuid)
    }

    func remove(uuid: String, fireNotification: Bool) {
        guard let episodeToRemove = DataManager.sharedManager.findPlaylistEpisode(uuid: uuid) else { return }

        FileLog.shared.addMessage("PlaybackQueue: removing \(episodeToRemove.title) episode")
        DataManager.sharedManager.delete(playlistEpisode: episodeToRemove)
        if SyncManager.isUserLoggedIn() {
            DataManager.sharedManager.saveUpNextRemove(episodeUuid: uuid)
            startSyncTimer()
        }

        refreshAppFiring(notificationName: fireNotification ? Constants.Notifications.upNextEpisodeRemoved : nil, notificationObject: uuid)
    }

    func removeTopEpisode(fireNotification: Bool) {
        guard let topEpisode = topEpisode else { return }

        FileLog.shared.addMessage("Remove Top Episode \(topEpisode.title ?? "Untitled")")
        remove(episode: topEpisode, fireNotification: fireNotification)
    }

    func add(episode: BaseEpisode, fireNotification: Bool, partOfBulkAdd: Bool = false, toTop: Bool = false) {
        if let existingEpisode = DataManager.sharedManager.findPlaylistEpisode(uuid: episode.uuid) {
            existingEpisode.episodePosition = DataManager.sharedManager.positionForPlaylistEpisode(bottomOfList: !toTop)
            DataManager.sharedManager.save(playlistEpisode: existingEpisode)
        } else {
            let newEpisode = PlaylistEpisode()
            newEpisode.episodeUuid = episode.uuid
            newEpisode.episodePosition = DataManager.sharedManager.positionForPlaylistEpisode(bottomOfList: !toTop)
            newEpisode.title = episode.displayableTitle()
            newEpisode.podcastUuid = episode.parentIdentifier()

            DataManager.sharedManager.save(playlistEpisode: newEpisode)
        }

        if !partOfBulkAdd, SyncManager.isUserLoggedIn() {
            if toTop {
                DataManager.sharedManager.saveUpNextAddToTop(episodeUuid: episode.uuid)
            } else {
                DataManager.sharedManager.saveUpNextAddToBottom(episodeUuid: episode.uuid)
            }

            startSyncTimer()
        }

        // don't update until this bulk operation is complete
        if partOfBulkAdd { return }

        FileLog.shared.addMessage("PlaybackQueue: added single episode \(episode.title ?? "Untitled")")

        let notificationName = fireNotification ? Constants.Notifications.upNextEpisodeAdded : nil
        refreshAppFiring(notificationName: notificationName, notificationObject: episode.uuid)
    }

    func bulkOperationDidComplete() {
        saveReplaceIfRequired()

        FileLog.shared.addMessage("PlaybackQueue: finished bulk add")

        refreshAppFiring(notificationName: Constants.Notifications.upNextQueueChanged)
    }

    func bulkDelete(uuids: [String]) {
        DataManager.sharedManager.deleteAllUpNextEpisodesIn(uuids: uuids)
        saveReplaceIfRequired()
        refreshAppFiring(notificationName: Constants.Notifications.upNextQueueChanged)
    }

    func bulkAdd(_ episodes: [BaseEpisode], toTop: Bool = false) {
        let topPosition = DataManager.sharedManager.positionForPlaylistEpisode(bottomOfList: !toTop)
        var playlistEpisodes = [PlaylistEpisode]()
        for (index, episode) in episodes.enumerated() {
            if let existingEpisode = DataManager.sharedManager.findPlaylistEpisode(uuid: episode.uuid) {
                existingEpisode.episodePosition = topPosition + Int32(index)
                playlistEpisodes.append(existingEpisode)
            } else {
                let newEpisode = PlaylistEpisode()
                newEpisode.episodeUuid = episode.uuid
                newEpisode.episodePosition = topPosition + Int32(index)
                newEpisode.title = episode.displayableTitle()
                newEpisode.podcastUuid = episode.parentIdentifier()
                playlistEpisodes.append(newEpisode)
            }
        }
        DataManager.sharedManager.save(playlistEpisodes: playlistEpisodes)

        bulkOperationDidComplete()
    }

    func bulkMove(_ playlistEpisodes: [PlaylistEpisode], toTop: Bool) {
        let firstIndex = DataManager.sharedManager.positionForPlaylistEpisode(bottomOfList: !toTop)
        for (index, playlistEpisode) in playlistEpisodes.enumerated() {
            playlistEpisode.episodePosition = Int32(index) + firstIndex
        }

        DataManager.sharedManager.save(playlistEpisodes: playlistEpisodes)

        bulkOperationDidComplete()
    }

    func persistLocalCopyAsReplace() {
        saveReplaceIfRequired()
        startSyncTimer()
    }

    func pushNewCurrentlyPlaying(episode: BaseEpisode) {
        if let existingEpisode = DataManager.sharedManager.findPlaylistEpisode(uuid: episode.uuid) {
            DataManager.sharedManager.movePlaylistEpisode(from: Int(existingEpisode.episodePosition), to: 0)
        } else {
            let newEpisode = PlaylistEpisode()
            newEpisode.episodeUuid = episode.uuid
            newEpisode.episodePosition = -1
            newEpisode.title = episode.displayableTitle()
            newEpisode.podcastUuid = episode.parentIdentifier()

            DataManager.sharedManager.save(playlistEpisode: newEpisode)
            DataManager.sharedManager.movePlaylistEpisode(from: -1, to: 0)
        }

        if SyncManager.isUserLoggedIn() {
            DataManager.sharedManager.saveUpNextAddNowPlaying(episodeUuid: episode.uuid)
            startSyncTimer()
        }

        refreshAppFiring(notificationName: Constants.Notifications.upNextQueueChanged)
    }

    func moveEpisode(from: Int, to: Int) {
        // externally to the rest of the app, the now playing episode isn't in up next, so we need to increment these indexes
        DataManager.sharedManager.movePlaylistEpisode(from: from + 1, to: to + 1)

        saveReplaceIfRequired()

        refreshAppFiring(notificationName: Constants.Notifications.upNextQueueChanged)
    }

    func insert(episode: BaseEpisode, position: Int) {
        let existingEpisode = contains(episode: episode)

        if existingEpisode {
            move(episode: episode, to: position)
        } else {
            let newEpisode = PlaylistEpisode()
            newEpisode.episodeUuid = episode.uuid
            newEpisode.episodePosition = Int32(position + 1)
            newEpisode.title = episode.displayableTitle()
            newEpisode.podcastUuid = episode.parentIdentifier()

            DataManager.sharedManager.save(playlistEpisode: newEpisode)
            saveReplaceIfRequired()
        }

        refreshAppFiring(notificationName: Constants.Notifications.upNextQueueChanged)
    }

    func move(episode: BaseEpisode, to: Int, fireNotification: Bool = true) {
        guard let episodeToMove = DataManager.sharedManager.findPlaylistEpisode(uuid: episode.uuid) else { return }

        // externally to the rest of the app, the now playing episode isn't in up next, so we need to increment this index
        DataManager.sharedManager.movePlaylistEpisode(from: Int(episodeToMove.episodePosition), to: to + 1)

        saveReplaceIfRequired()

        refreshAppFiring(notificationName: fireNotification ? Constants.Notifications.upNextQueueChanged : nil)
    }

    func overrideAllEpisodesWith(episode: BaseEpisode) {
        FileLog.shared.addMessage("PlaybackQueue: overrideAllEpisodesWith with \(episode.title ?? "Untitled")")
        DataManager.sharedManager.deleteAllUpNextEpisodes()
        saveReplaceIfRequired()

        pushNewCurrentlyPlaying(episode: episode)
    }

    func removeAllEpisodes() {
        FileLog.shared.addMessage("PlaybackQueue: removeAllEpisodes called, clearing list")

        DataManager.sharedManager.deleteAllUpNextEpisodes()

        topEpisode = nil
        saveReplaceIfRequired()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.upNextQueueChanged)
    }

    func clearUpNextList() {
        guard let topEpisode = topEpisode else { return }

        DataManager.sharedManager.deleteAllUpNextEpisodesExcept(episodeUuid: topEpisode.uuid)
        FileLog.shared.addMessage("PlaybackQueue: clearUpNextList called, clearing list")

        saveReplaceIfRequired()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.upNextQueueChanged)
    }

    func refreshList(checkForAutoDownload: Bool) {
        cacheTopEpisode()
        updateUpNextInfo()

        if checkForAutoDownload {
            checkAllForAutoDownload()
        }
    }

    func nowPlayingEpisodeChanged() {
        cacheTopEpisode()
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.currentlyPlayingEpisodeUpdated)
    }

    // MARK: - Querying

    func contains(episode: BaseEpisode) -> Bool {
        contains(episodeUuid: episode.uuid)
    }

    func contains(episodeUuid: String) -> Bool {
        let allEpisodes = DataManager.sharedManager.allUpNextPlaylistEpisodes()

        for playlistEpisode in allEpisodes {
            if playlistEpisode.episodeUuid == episodeUuid { return true }
        }

        return false
    }

    func allEpisodes(includeNowPlaying: Bool = true) -> [BaseEpisode] {
        if includeNowPlaying { return DataManager.sharedManager.allUpNextEpisodes() }

        var episodes = DataManager.sharedManager.allUpNextEpisodes()
        if episodes.count == 0 { return episodes }

        episodes.removeFirst()

        return episodes
    }

    func currentEpisode() -> BaseEpisode? {
        topEpisode
    }

    func upNextCount() -> Int {
        // the data manager counts the current episode, so we remove it here, since we don't expose that info to the rest of the app
        max(0, DataManager.sharedManager.playlistEpisodeCount() - 1)
    }

    func episodeAt(index: Int) -> BaseEpisode? {
        let actualIndex = index + 1 // the rest of the app doesn't treat the current episode as being at position 0
        if actualIndex < 0 { return nil }

        if let episode = DataManager.sharedManager.episodeInUpNextAt(index: actualIndex) {
            return episode
        }

        guard let playlistEpisode = DataManager.sharedManager.playlistEpisodeAt(index: actualIndex) else { return nil }

        let missingEpisode = UserEpisode()
        missingEpisode.title = playlistEpisode.title
        missingEpisode.uuid = playlistEpisode.episodeUuid
        missingEpisode.uploadStatus = UploadStatus.missing.rawValue
        missingEpisode.imageColor = 1

        return missingEpisode
    }

    func upNextTotalDuration(includePlayingEpisode: Bool) -> TimeInterval {
        let episodes = allEpisodes(includeNowPlaying: includePlayingEpisode)

        return episodes.map { $0.duration - $0.playedUpTo }.reduce(0, +)
    }

    // MARK: - Persistence

    func loadPersistedQueue() {
        cacheTopEpisode()
    }

    // MARK: - Private Helpers

    func updateUpNextInfo() {
        #if !os(watchOS)
            WidgetHelper.shared.updateSharedUpNext()
        #endif
    }

    private func checkAllForAutoDownload() {
        if !Settings.downloadUpNextEpisodes() { return }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            let episodes = self.allEpisodes()
            for episode in episodes {
                self.autoDownloadIfRequired(episode: episode)
            }
        }
    }

    private func autoDownloadIfRequired(episode: BaseEpisode) {
        if !Settings.downloadUpNextEpisodes() || episode.queued() || episode.downloaded(pathFinder: DownloadManager.shared) { return }

        if Settings.autoDownloadMobileDataAllowed() || NetworkUtils.shared.isConnectedToWifi() {
            DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, autoDownloadStatus: .autoDownloaded)
        } else {
            DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: true, autoDownloadStatus: .autoDownloaded)
        }
    }

    private func cacheTopEpisode() {
        topEpisode = episodeAt(index: -1)
    }

    private func refreshAppFiring(notificationName: Notification.Name?, notificationObject: Any? = nil) {
        refreshList(checkForAutoDownload: true)

        if let name = notificationName, let object = notificationObject {
            NotificationCenter.postOnMainThread(notification: name, object: object)
        } else if let name = notificationName {
            NotificationCenter.postOnMainThread(notification: name)
        }

        startSyncTimer()
    }

    private func saveReplaceIfRequired() {
        if !SyncManager.isUserLoggedIn() { return }

        var episodeUuids = [String]()
        for playlistEpisode in DataManager.sharedManager.allUpNextPlaylistEpisodes() {
            episodeUuids.append(playlistEpisode.episodeUuid)
        }

        FileLog.shared.addMessage("PlaybackQueue: Saving replace of \(episodeUuids.count) episodes")

        DataManager.sharedManager.saveReplace(episodeList: episodeUuids)

        startSyncTimer()
    }

    // MARK: - Sync Timer

    private func startSyncTimer() {
        cancelSyncTimer()

        // schedule the timer on a thread that has a run loop, the main thread being a good option
        if Thread.isMainThread {
            syncTimer = Timer.scheduledTimer(timeInterval: syncTimerDelay, target: self, selector: #selector(syncTimerFired), userInfo: nil, repeats: false)
        } else {
            DispatchQueue.main.sync { [weak self] () in
                guard let self else { return }

                self.syncTimer = Timer.scheduledTimer(timeInterval: self.syncTimerDelay, target: self, selector: #selector(self.syncTimerFired), userInfo: nil, repeats: false)
            }
        }
    }

    private func cancelSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    @objc private func syncTimerFired() {
        RefreshManager.shared.syncUpNext()
    }
}
