import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchConnectivity

class WatchManager: NSObject, WCSessionDelegate {
    static let shared = WatchManager()

    let logFileRequestTimedAction = TimedActionHelper()

    func setup() {
        if !WCSession.isSupported() { return }

        WCSession.default.delegate = self
        WCSession.default.activate()

        NotificationCenter.default.addObserver(self, selector: #selector(updateWatchData), name: Constants.Notifications.filterChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastsDidRefresh), name: ServerNotifications.podcastsRefreshed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(podcastsDidRefresh), name: Constants.Notifications.opmlImportCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextQueueChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.playbackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.playbackEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.playbackPositionSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.playbackEffectsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(episodeStarredChanged(_:)), name: Constants.Notifications.episodeStarredChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(autoDownloadChanged), name: Constants.Notifications.watchAutoDownloadSettingsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.podcastChapterChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: Constants.Notifications.podcastChaptersDidUpdate, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        updateWatchData()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // we don't need to do anything here
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Begin the activation process for the new Apple Watch.
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        updateWatchData()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let messageType = message[WatchConstants.Messages.messageType] as? String else { return }

        if WatchConstants.Messages.DataRequest.type == messageType {
            updateWatchData()
        } else if WatchConstants.Messages.PlayEpisodeRequest.type == messageType {
            if let episodeUuid = message[WatchConstants.Messages.PlayEpisodeRequest.episodeUuid] as? String {
                handlePlayRequest(episodeUuid: episodeUuid)
            }
        } else if WatchConstants.Messages.PlayPauseRequest.type == messageType {
            AnalyticsPlaybackHelper.shared.currentSource = .watch
            if PlaybackManager.shared.playing() {
                PlaybackManager.shared.pause()
            } else {
                PlaybackManager.shared.play()
            }
        } else if WatchConstants.Messages.SkipBackRequest.type == messageType {
            AnalyticsPlaybackHelper.shared.currentSource = .watch
            PlaybackManager.shared.skipBack()
        } else if WatchConstants.Messages.SkipForwardRequest.type == messageType {
            AnalyticsPlaybackHelper.shared.currentSource = .watch
            PlaybackManager.shared.skipForward()
        } else if WatchConstants.Messages.StarRequest.type == messageType {
            if let starred = message[WatchConstants.Messages.StarRequest.star] as? Bool, let uuid = message[WatchConstants.Messages.StarRequest.episodeUuid] as? String {
                handleStarRequest(starred: starred, episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.AddToUpNextRequest.type == messageType {
            if let toTop = message[WatchConstants.Messages.AddToUpNextRequest.toTop] as? Bool, let uuid = message[WatchConstants.Messages.AddToUpNextRequest.episodeUuid] as? String {
                handleAddToUpnext(episodeUuid: uuid, toTop: toTop)
            }
        } else if WatchConstants.Messages.RemoveFromUpNextRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.RemoveFromUpNextRequest.episodeUuid] as? String {
                handleRemoveFromUpnext(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.MarkPlayedRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.MarkPlayedRequest.episodeUuid] as? String {
                handleMarkPlayed(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.MarkUnplayedRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.MarkUnplayedRequest.episodeUuid] as? String {
                handleMarkUnplayed(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.DownloadRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.DownloadRequest.episodeUuid] as? String {
                handleDownload(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.StopDownloadRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.StopDownloadRequest.episodeUuid] as? String {
                handleStopDownload(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.DeleteDownloadRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.DeleteDownloadRequest.episodeUuid] as? String {
                handleDeleteDownload(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.ArchiveRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.ArchiveRequest.episodeUuid] as? String {
                handleArchive(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.UnarchiveRequest.type == messageType {
            if let uuid = message[WatchConstants.Messages.UnarchiveRequest.episodeUuid] as? String {
                handleUnarchive(episodeUuid: uuid)
            }
        } else if WatchConstants.Messages.ClearUpNextRequest.type == messageType {
            PlaybackManager.shared.queue.clearUpNextList()
        } else if WatchConstants.Messages.ChangeChapterRequest.type == messageType {
            if let nextChapter = message[WatchConstants.Messages.ChangeChapterRequest.nextChapter] as? Bool {
                handleChangeChapter(next: nextChapter)
            }
        } else if WatchConstants.Messages.IncreaseSpeedRequest.type == messageType {
            let effects = PlaybackManager.shared.effects()
            let desiredSpeed = effects.playbackSpeed + 0.1
            if desiredSpeed <= SharedConstants.PlaybackEffects.maximumPlaybackSpeed {
                effects.playbackSpeed = desiredSpeed
                PlaybackManager.shared.changeEffects(effects)
            }
        } else if WatchConstants.Messages.DecreaseSpeedRequest.type == messageType {
            let effects = PlaybackManager.shared.effects()
            let desiredSpeed = effects.playbackSpeed - 0.1
            if desiredSpeed >= SharedConstants.PlaybackEffects.minimumPlaybackSpeed {
                effects.playbackSpeed = desiredSpeed
                PlaybackManager.shared.changeEffects(effects)
            }
        } else if WatchConstants.Messages.TrimSilenceRequest.type == messageType {
            guard let enabled = message[WatchConstants.Messages.TrimSilenceRequest.enabled] as? Bool else { return }

            let effects = PlaybackManager.shared.effects()
            effects.trimSilence = enabled ? .low : .off
            PlaybackManager.shared.changeEffects(effects)
        } else if WatchConstants.Messages.VolumeBoostRequest.type == messageType {
            guard let enabled = message[WatchConstants.Messages.VolumeBoostRequest.enabled] as? Bool else { return }

            let effects = PlaybackManager.shared.effects()
            effects.volumeBoost = enabled
            PlaybackManager.shared.changeEffects(effects)
        } else if WatchConstants.Messages.ChangeSpeedIntervalRequest.type == messageType {
            let effects = PlaybackManager.shared.effects()
            effects.toggleDefinedSpeedInterval()

            PlaybackManager.shared.changeEffects(effects)
        } else if WatchConstants.Messages.SignificantSyncableUpdate.type == messageType {
            RefreshManager.shared.refreshPodcasts()
        } else if WatchConstants.Messages.MinorSyncableUpdate.type == messageType {
            if DateUtil.hasEnoughTimePassed(since: ServerSettings.lastRefreshEndTime(), time: 30.minutes) {
                RefreshManager.shared.refreshPodcasts()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let messageType = message[WatchConstants.Messages.messageType] as? String else { return }

        if WatchConstants.Messages.FilterRequest.type == messageType {
            if let filterUuid = message[WatchConstants.Messages.FilterRequest.filterUuid] as? String {
                let response = handleFilterRequest(filterUuid: filterUuid)
                replyHandler(response)
            }
        } else if WatchConstants.Messages.DownloadsRequest.type == messageType {
            let response = handleDownloadsRequest()
            replyHandler(response)
        } else if WatchConstants.Messages.UserEpisodeRequest.type == messageType {
            let response = handleUserEpisodeRequest()
            replyHandler(response)
        } else if WatchConstants.Messages.LoginDetailsRequest.type == messageType {
            let response = handleLoginDetailsRequest()
            replyHandler(response)
        }

        // send blank response to messages we don't know about or for things we can't find info on
        replyHandler([String: Any]())
    }

    // MARK: Handler methods

    private func handleDownload(episodeUuid: String) {
        DownloadManager.shared.addToQueue(episodeUuid: episodeUuid, fireNotification: true, autoDownloadStatus: .notSpecified)
        sendStateToWatch()
    }

    private func handleStopDownload(episodeUuid: String) {
        DownloadManager.shared.removeFromQueue(episodeUuid: episodeUuid, fireNotification: true, userInitiated: true)
        sendStateToWatch()
    }

    private func handleDeleteDownload(episodeUuid: String) {
        guard let baseEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return }

        if let userEpisode = baseEpisode as? UserEpisode {
            UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode)
        } else if let episode = baseEpisode as? Episode {
            EpisodeManager.deleteDownloadedFiles(episode: episode, userInitated: true)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
        }
        sendStateToWatch()
    }

    private func handleArchive(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return }

        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
        sendStateToWatch()
    }

    private func handleUnarchive(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return }

        EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
        sendStateToWatch()
    }

    private func handleChangeChapter(next: Bool) {
        if next {
            PlaybackManager.shared.skipToNextChapter()
        } else {
            PlaybackManager.shared.skipToPreviousChapter()
        }
    }

    private func handleMarkPlayed(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return }

        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        sendStateToWatch()
    }

    private func handleMarkUnplayed(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return }

        EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
        sendStateToWatch()
    }

    private func handleAddToUpnext(episodeUuid: String, toTop: Bool) {
        guard let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return }

        // remove it first so that this can be used as a move to top/bottom as well
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: false, userInitiated: false)
        PlaybackManager.shared.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: toTop, userInitiated: true)
    }

    private func handleRemoveFromUpnext(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return }

        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
    }

    private func handleStarRequest(starred: Bool, episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else { return }

        EpisodeManager.setStarred(starred, episode: episode, updateSyncStatus: SyncManager.isUserLoggedIn())
    }

    private func handlePlayRequest(episodeUuid: String) {
        guard let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { return }

        PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
    }

    private func handleFilterRequest(filterUuid: String) -> [String: Any] {
        guard let filter = DataManager.sharedManager.findFilter(uuid: filterUuid) else { return [String: Any]() }

        let episodeQuery = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.maxListItemsToSendToWatch)
        let episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: episodeQuery, arguments: nil)

        var convertedEpisodes = [[String: Any]]()
        for episode in episodes {
            if let convertedEpisode = convertForWatch(episode: episode) {
                convertedEpisodes.append(convertedEpisode)
            }
        }

        let response = [WatchConstants.Messages.FilterResponse.episodes: convertedEpisodes]

        return response
    }

    private func handleDownloadsRequest() -> [String: Any] {
        let episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "episodeStatus == \(DownloadStatus.downloaded.rawValue) ORDER BY lastDownloadAttemptDate DESC LIMIT \(Constants.Limits.maxListItemsToSendToWatch)", arguments: nil)

        var convertedEpisodes = [[String: Any]]()
        for episode in episodes {
            if let convertedEpisode = convertForWatch(episode: episode) {
                convertedEpisodes.append(convertedEpisode)
            }
        }

        let response = [WatchConstants.Messages.DownloadsResponse.episodes: convertedEpisodes]

        return response
    }

    private func handleUserEpisodeRequest() -> [String: Any] {
        let sortBy = UploadedSort(rawValue: Settings.userEpisodeSortBy()) ?? UploadedSort.newestToOldest
        var episodes: [UserEpisode]
        if SubscriptionHelper.hasActiveSubscription() {
            episodes = DataManager.sharedManager.allUserEpisodes(sortedBy: sortBy, limit: Constants.Limits.maxListItemsToSendToWatch)
        } else {
            episodes = DataManager.sharedManager.allUserEpisodesDownloaded(sortedBy: sortBy, limit: Constants.Limits.maxListItemsToSendToWatch)
        }
        var convertedEpisodes = [[String: Any]]()
        for episode in episodes {
            if let convertedEpisode = convertForWatch(episode: episode) {
                convertedEpisodes.append(convertedEpisode)
            }
        }

        let response = [WatchConstants.Messages.UserEpisodeResponse.episodes: convertedEpisodes]

        return response
    }

    private func handleLoginDetailsRequest() -> [String: Any] {
        var response = [
            WatchConstants.Messages.LoginDetailsResponse.username: ServerSettings.syncingEmail() ?? ""
        ]

        if let password = ServerSettings.syncingPassword() {
            response[WatchConstants.Messages.LoginDetailsResponse.password] = password
        }
        else if let refreshToken = ServerSettings.refreshToken {
            response[WatchConstants.Messages.LoginDetailsResponse.refreshToken] = refreshToken
        }

        Settings.clearLoginDetailsUpdated()
        return response
    }

    // MARK: - App Notifications

    @objc private func updateWatchData() {
        sendStateToWatch()
    }

    @objc private func podcastsDidRefresh() {
        // only send the data if the user is not signed in, if they are, then wait for a sync complete
        if !SyncManager.isUserLoggedIn() {
            sendStateToWatch()
        }
    }

    @objc private func syncCompleted() {
        sendStateToWatch()
    }

    @objc private func upNextChanged() {
        sendStateToWatch()
    }

    @objc private func playbackStateChanged() {
        sendStateToWatch()
    }

    @objc private func episodeStarredChanged(_ notification: Notification) {
        guard let uuid = notification.object as? String, PlaybackManager.shared.queue.contains(episodeUuid: uuid) else { return }

        // currently the watch only needs to know if the starred status of something in Up Next changes
        sendStateToWatch()
    }

    @objc private func autoDownloadChanged() {
        sendStateToWatch()
    }

    private func sendStateToWatch() {
        if !WCSession.isSupported() { return }

        let session = WCSession.default

        // only send data when we have a valid connection
        if session.activationState != .activated || session.isPaired == false || session.isWatchAppInstalled == false { return }

        var applicationDict = [String: Any]()
        applicationDict[WatchConstants.Keys.messageVersion] = WatchConstants.Values.messageVersion

        applicationDict[WatchConstants.Keys.filters] = serializeFilters()
        applicationDict[WatchConstants.Keys.nowPlayingInfo] = serializeNowPlaying()
        applicationDict[WatchConstants.Keys.upNextInfo] = serializeUpNext()
        applicationDict[WatchConstants.Keys.autoArchivePlayedAfter] = Settings.autoArchivePlayedAfter()
        applicationDict[WatchConstants.Keys.autoArchiveStarredEpisodes] = Settings.archiveStarredEpisodes()
        if let podcastsWithOverrideGlobalArchive = serializePodcastArchiveSettings() {
            applicationDict[WatchConstants.Keys.podcastSettings] = podcastsWithOverrideGlobalArchive
        }
        if Settings.loginDetailsUpdated() {
            applicationDict[WatchConstants.Keys.loginChanged] = true
        }

        applicationDict[WatchConstants.Keys.upNextDownloadEpisodeCount] = Settings.watchAutoDownloadUpNextEnabled() == true ? Settings.watchAutoDownloadUpNextCount() : 0
        applicationDict[WatchConstants.Keys.upNextAutoDeleteEpisodeCount] = Settings.watchAutoDeleteUpNext() == true ? Settings.watchAutoDownloadUpNextCount() : 25
        do {
            try session.updateApplicationContext(applicationDict)
        } catch {
            FileLog.shared.addMessage("WatchManager sendStateToWatch failed \(error.localizedDescription)")
        }
    }

    // MARK: - Encoding

    private func serializeNowPlaying() -> [String: Any] {
        var nowPlayingInfo = [String: Any]()
        let playbackManager = PlaybackManager.shared
        if let playingEpisode = playbackManager.currentEpisode() {
            nowPlayingInfo[WatchConstants.Keys.nowPlayingEpisode] = convertForWatch(episode: playingEpisode)
            nowPlayingInfo[WatchConstants.Keys.nowPlayingSubtitle] = playingEpisode.subTitle()
            nowPlayingInfo[WatchConstants.Keys.nowPlayingStatus] = playbackManager.playing() ? WatchConstants.PlayingStatus.playing : WatchConstants.PlayingStatus.paused
            if let playingEpisode = playingEpisode as? Episode, let podcast = playingEpisode.parentPodcast() {
                let color = ColorManager.darkThemeTintForPodcast(podcast)
                nowPlayingInfo[WatchConstants.Keys.nowPlayingColor] = color.hexString()
            } else {
                nowPlayingInfo[WatchConstants.Keys.nowPlayingColor] = UIColor.white.hexString()
            }

            let hasChapters = playbackManager.chapterCount() > 0
            nowPlayingInfo[WatchConstants.Keys.nowPlayingHasChapters] = hasChapters
            let chapterTitle = playbackManager.currentChapters().title()
            nowPlayingInfo[WatchConstants.Keys.nowPlayingChapterTitle] = chapterTitle

            let duration = playbackManager.duration()
            let currentTime = playbackManager.currentTime()
            nowPlayingInfo[WatchConstants.Keys.nowPlayingCurrentTime] = currentTime
            nowPlayingInfo[WatchConstants.Keys.nowPlayingDuration] = duration > 0 ? duration : 0

            nowPlayingInfo[WatchConstants.Keys.nowPlayingUpNextCount] = playbackManager.queue.upNextCount()

            let effects = playbackManager.effects()
            nowPlayingInfo[WatchConstants.Keys.nowPlayingTrimSilence] = effects.trimSilence.isEnabled()
            nowPlayingInfo[WatchConstants.Keys.nowPlayingVolumeBoost] = effects.volumeBoost
            nowPlayingInfo[WatchConstants.Keys.nowPlayingSpeed] = effects.playbackSpeed
        }

        nowPlayingInfo[WatchConstants.Keys.nowPlayingSkipBackAmount] = ServerSettings.skipBackTime()
        nowPlayingInfo[WatchConstants.Keys.nowPlayingSkipForwardAmount] = ServerSettings.skipForwardTime()

        return nowPlayingInfo
    }

    private func serializeUpNext() -> [[String: Any]] {
        var upNextList = [[String: Any]]()

        let upNextEpisodes = PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: false)
        if upNextEpisodes.count == 0 { return upNextList }

        let truncatedList = Array(upNextEpisodes.prefix(Constants.Limits.maxListItemsToSendToWatch))
        for episode in truncatedList {
            if let convertedEpisode = convertForWatch(episode: episode) {
                upNextList.append(convertedEpisode)
            }
        }

        return upNextList
    }

    private func serializeFilters() -> [[String: Any]] {
        let allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        var convertedFilters = [[String: Any]]()
        for filter in allFilters {
            var convertedFilter = [String: Any]()
            convertedFilter[WatchConstants.Keys.filterTitle] = filter.playlistName
            convertedFilter[WatchConstants.Keys.filterUuid] = filter.uuid
            if let iconName = filter.iconImageName() {
                convertedFilter[WatchConstants.Keys.filterIcon] = iconName
            }

            convertedFilters.append(convertedFilter)
        }

        return convertedFilters
    }

    private func serializePodcastArchiveSettings() -> [[String: Any]]? {
        let podcastsWithOverride = DataManager.sharedManager.allOverrideGlobalArchivePodcasts()
        guard podcastsWithOverride.count > 0 else { return nil }

        var podcastArchiveSettings = [[String: Any]]()
        podcastsWithOverride.forEach {
            var podcastSettings = [String: Any]()
            podcastSettings[WatchConstants.Keys.podcastUuid] = $0.uuid
            podcastSettings[WatchConstants.Keys.podcastOverrideGlobalArchive] = $0.overrideGlobalArchive
            podcastSettings[WatchConstants.Keys.podcastAutoArchivePlayedAfter] = $0.autoArchivePlayedAfter
            podcastArchiveSettings.append(podcastSettings)
        }
        return podcastArchiveSettings
    }

    // MARK: - Conversion

    private func convertForWatch(episode: BaseEpisode) -> [String: Any]? {
        var convertedEpisode = [String: Any]()

        if let episode = episode as? Episode {
            convertedEpisode[WatchConstants.Keys.episodeTypeKey] = "Episode"
            convertedEpisode[WatchConstants.Keys.episodeSerialisedKey] = episode.encodeToMap()
        } else if let episode = episode as? UserEpisode {
            convertedEpisode[WatchConstants.Keys.episodeTypeKey] = "UserEpisode"
            convertedEpisode[WatchConstants.Keys.episodeSerialisedKey] = episode.encodeToMap()
        }

        return convertedEpisode
    }
}
