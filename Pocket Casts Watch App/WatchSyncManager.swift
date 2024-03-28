import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

class WatchSyncManager {
    static let shared = WatchSyncManager()
    static let watchMinTimeBetweenPeriodicRefreshes = 15.minutes
    static let watchMinTimeBetweenPeriodicSubscriptionCheck = 24.hours

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(significantEpisodeChangeMade), name: Constants.Notifications.episodePlayStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(significantEpisodeChangeMade), name: Constants.Notifications.episodeArchiveStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(minorEpisodeChangeMade), name: Constants.Notifications.episodeDurationChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(significantEpisodeChangeMade), name: Constants.Notifications.episodeStarredChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkSubscriptionStatus), name: NSNotification.Name(rawValue: WatchConstants.Notifications.loginStatusUpdated), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusUpdated), name: Notification.Name(rawValue: ServerNotifications.subscriptionStatusChanged.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleContextUpdate), name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setup() {
        let defaults = UserDefaults.standard

        // check to see that this app has a unique ID, if not create one
        let uniqueId = defaults.string(forKey: Constants.UserDefaults.appId)
        if uniqueId?.count ?? 0 < 1 {
            let uuid = UUID().uuidString
            defaults.set(uuid, forKey: Constants.UserDefaults.appId)
            defaults.synchronize()
        }

        ServerConfig.shared.syncDelegate = self
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared

        performUpdateIfRequired(updateKey: "CreatedDefPlaylistsV2") {
            PlaylistManager.createDefaultFilters()
        }

        performUpdateIfRequired(updateKey: "FirstRunDefaults") {
            // these are considered defaults for a new app install
            ServerSettings.setSkipBackTime(10, syncChange: false)
            ServerSettings.setSkipForwardTime(45, syncChange: false)

            Settings.setAutoArchivePlayedAfter(0)
            Settings.setAutoArchiveInactiveAfter(-1)
            Settings.setArchiveStarredEpisodes(false)

            Settings.setShouldDeleteWhenPlayed(true)
            Settings.setMobileDataAllowed(true)
        }

        performUpdateIfRequired(updateKey: "v7_11Run") {
            if let email = ServerSettings.syncingEmailLegacy() {
                FileLog.shared.addMessage("Migrating email address from preferences to Keychain")
                ServerSettings.setSyncingEmail(email: email)
                ServerSettings.removeLegacySyncingEmail()
            }
        }
        UserEpisodeManager.removeOrphanedUserEpisodes()
        DownloadManager.shared.clearStuckDownloads()
    }

    private func performUpdateIfRequired(updateKey: String, update: () -> Void) {
        if UserDefaults.standard.bool(forKey: updateKey) { return } // already performed this update

        update()
        UserDefaults.standard.set(true, forKey: updateKey)
    }

    @objc func handleContextUpdate() {
        if updateLoginDetailsIfRequired() {
            return
        } else {
            if isPlusUser(), WKApplication.shared().applicationState == .background, compareUpNextLists() == .watchNeedsUpdate, !SyncManager.isFirstSyncInProgress() {
                let subscribedPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                BackgroundSyncManager.shared.performBackgroundRefresh(subscribedPodcasts: subscribedPodcasts)
            } else {
                loginAndRefreshIfRequired()
            }
        }
        updatePodcastSettings()
    }

    func loginAndRefreshIfRequired() {
        if SyncManager.isUserLoggedIn() {
            periodicCheckSubscriptionStatus()
            if SubscriptionHelper.hasActiveSubscription() {
                let comparisonResult = compareUpNextLists()
                if comparisonResult == .watchNeedsUpdate || comparisonResult == .notEnoughInformation {
                    RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
                } else {
                    periodicRefresh()
                }
            }
        } else {
            FileLog.shared.addMessage("Non Plus user - getting login details")
            SessionManager.shared.requestLoginDetails(replyHandler: { response in
                let username = response[WatchConstants.Messages.LoginDetailsResponse.username] as? String ?? ""
                let password = response[WatchConstants.Messages.LoginDetailsResponse.password] as? String ?? ""
                let refreshToken = response[WatchConstants.Messages.LoginDetailsResponse.refreshToken] as? String

                ServerSettings.setSyncingEmail(email: username)
                ServerSettings.saveSyncingPassword(password)
                ServerSettings.refreshToken = refreshToken

                if !username.isEmpty {
                    self.login()
                } else {
                    FileLog.shared.addMessage("No username or password, don't attempt login")
                }
            }, errorHandler: { error in
                FileLog.shared.addMessage("Failed to get login details: \(error?.localizedDescription ?? "No error information")")
            })
        }
    }

    func login() {
        Task {
            do {
                try await AuthenticationHelper.refreshLogin()
                DispatchQueue.main.async {
                    self.handleLogin()
                }
            }
            catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
    }

    private func handleLogin() {
        FileLog.shared.addMessage("Login successful")
        self.checkSubscriptionStatus()
        NotificationCenter.default.post(name: Notification.Name(rawValue: WatchConstants.Notifications.loginStatusUpdated), object: nil)
        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
    }

    private func handleError(_ error: Error) {
        let error = error as? APIError

        if let message = error?.rawValue, !message.isEmpty {
            FileLog.shared.addMessage("FAILED Login \(message)")
        } else {
            FileLog.shared.addMessage("FAILED Login - no message")
        }
        SyncManager.signout()
        NotificationCenter.default.post(name: Notification.Name(rawValue: WatchConstants.Notifications.loginStatusUpdated), object: nil)
        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
    }

    @objc func handleUpdateFromPhone() {
        _ = updateLoginDetailsIfRequired()
        updatePodcastSettings()
    }

    @objc func updateLoginDetailsIfRequired() -> Bool {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let loginChanged = data[WatchConstants.Keys.loginChanged] as? Bool, loginChanged else {
            return false
        }

        SessionManager.shared.requestLoginDetails(replyHandler: { response in
            let username = response[WatchConstants.Messages.LoginDetailsResponse.username] as? String ?? ""
            let password = response[WatchConstants.Messages.LoginDetailsResponse.password] as? String ?? ""
            let refreshToken = response[WatchConstants.Messages.LoginDetailsResponse.refreshToken] as? String

            ServerSettings.setSyncingEmail(email: username)
            ServerSettings.saveSyncingPassword(password)
            ServerSettings.refreshToken = refreshToken

            if SyncManager.isUserLoggedIn(), username.isEmpty {
                FileLog.shared.addMessage("Logging out as phone has logged out ")
                SyncManager.signout()
                WKApplication.shared().visibleInterfaceController?.popToRootController()
            } else if !SyncManager.isUserLoggedIn() {
                self.login()
            }
        }, errorHandler: { error in
            FileLog.shared.addMessage("Failed to get login details: \(error?.localizedDescription ?? "No error information")")
        })
        return true
    }

    @objc func checkSubscriptionStatus() {
        if SyncManager.isUserLoggedIn() {
            ApiServerHandler.shared.retrieveSubscriptionStatus()
        }
    }

    func periodicCheckSubscriptionStatus() {
        if DateUtil.hasEnoughTimePassed(since: UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.lastSubscriptionStatusTime) as? Date, time: WatchSyncManager.watchMinTimeBetweenPeriodicSubscriptionCheck) {
            checkSubscriptionStatus()
        }
    }

    @objc private func subscriptionStatusUpdated() {
        UserDefaults.standard.set(Date(), forKey: WatchConstants.UserDefaults.lastSubscriptionStatusTime)
    }

    private func periodicRefresh() {
        if DateUtil.hasEnoughTimePassed(since: ServerSettings.lastRefreshEndTime(), time: WatchSyncManager.watchMinTimeBetweenPeriodicRefreshes) {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
        }
    }

    func updatePodcastSettings() {
        guard isPlusUser(), let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any] else { return }

        if let autoArchivePlayedAfter = data[WatchConstants.Keys.autoArchivePlayedAfter] as? TimeInterval {
            Settings.setAutoArchivePlayedAfter(autoArchivePlayedAfter)
        }

        if let autoArchiveStarred = data[WatchConstants.Keys.autoArchiveStarredEpisodes] as? Bool {
            Settings.setArchiveStarredEpisodes(autoArchiveStarred)
        }

        guard let podcastSettings = data[WatchConstants.Keys.podcastSettings] as? [[String: Any]] else { return }

        for podcastSetting in podcastSettings {
            guard let podcastUuid = podcastSetting[WatchConstants.Keys.podcastUuid] as? String, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) else { continue }

            if let overrideGlobalArchive = podcastSetting[WatchConstants.Keys.podcastOverrideGlobalArchive] as? Bool {
                podcast.isAutoArchiveOverridden = overrideGlobalArchive
            }

            if let autoArchivePlayedAfter = podcastSetting[WatchConstants.Keys.podcastAutoArchivePlayedAfter] as? TimeInterval {
                podcast.autoArchivePlayedAfterTime = autoArchivePlayedAfter
            }
            DataManager.sharedManager.save(podcast: podcast)
        }
    }

    // MARK: - Change Notifications

    private enum ChangeNotification {
        case significant, minor, none
    }

    private var pendingChangeNotification = ChangeNotification.none
    func syncThenNotifyPhone(significantChange: Bool, syncRequired: Bool) {
        if significantChange {
            pendingChangeNotification = .significant
        } else if pendingChangeNotification == .none {
            pendingChangeNotification = .minor
        }

        if syncRequired {
            RefreshManager.shared.refreshPodcasts()
        } else {
            sendPendingChangeMessage()
        }
    }

    @objc private func significantEpisodeChangeMade() {
        syncThenNotifyPhone(significantChange: true, syncRequired: true)
    }

    @objc private func minorEpisodeChangeMade() {
        syncThenNotifyPhone(significantChange: false, syncRequired: true)
    }

    @objc private func syncCompleted() {
        checkForUpNextAutoDownloads()
        sendPendingChangeMessage()
    }

    private func sendPendingChangeMessage() {
        if pendingChangeNotification == .significant {
            SessionManager.shared.significantSyncableUpdate()
        } else if pendingChangeNotification == .minor {
            SessionManager.shared.minorSyncableUpdate()
        }

        pendingChangeNotification = .none
    }

    enum upNextComparisonResult: Int {
        case same, phoneNeedsUpdate, watchNeedsUpdate, notEnoughInformation
    }

    private func compareUpNextLists() -> upNextComparisonResult {
        let watchEpisodeCount = PlaybackManager.shared.queue.upNextCount()

        guard let phoneEpisodes = WatchDataManager.upNextEpisodes(), phoneEpisodes.count > 0 else {
            if watchEpisodeCount == 0 {
                return .same
            } else {
                return .phoneNeedsUpdate
            }
        }

        let phoneUpNextCount = WatchDataManager.upNextCount()
        // The phone sends us a truncated list, and if the total count is higher than that we can't determine which list is newer because we're missing info
        if phoneUpNextCount > phoneEpisodes.count { return .notEnoughInformation }

        let watchEpisodes = PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: false)
        if phoneEpisodes.count == watchEpisodes.count {
            // if they are both 0, nothing to do
            if watchEpisodes.count == 0 {
                return .same
            }

            var allMatch = true
            for (index, episode) in watchEpisodes.enumerated() {
                if episode.uuid != phoneEpisodes[index].uuid {
                    allMatch = false
                    break
                }
            }
            if allMatch {
                return .same
            }
        }

        guard let lastServerRefresh = ServerSettings.lastRefreshStartTime() else {
            return .watchNeedsUpdate
        }

        if lastServerRefresh > WatchDataManager.lastDataTime() {
            return .phoneNeedsUpdate
        } else {
            return .watchNeedsUpdate
        }
    }

    func isPlusUser() -> Bool {
        SyncManager.isUserLoggedIn() && SubscriptionHelper.hasActiveSubscription()
    }
}
