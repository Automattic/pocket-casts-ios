import PocketCastsServer
import PocketCastsUtils
import WatchKit

class SourceInterfaceModel {

    var infoLabel: String = ""
    var lastRefreshLabel: String = ""

    var watchTitle: String = L10n.watch

    var signedInLabel: String = ""
    var profileImage: UIImage?
    var usernameLabel: String = ""

    var phoneSourceLabel: String = L10n.phone

    var phoneSourceSymbol: String = L10n.phone.sourceUnicode(isWatch: false)

    var watchSourceSymbol: String = L10n.watch.sourceUnicode(isWatch: true)

    var refreshDataLabel: String = L10n.watchSourceRefreshData

    var signInPrompt: String = L10n.watchSourceSignInInfo

    var refreshAccountLabel: String = L10n.watchSourceRefreshAccount

    var refreshAccountInfo: String = L10n.watchSourceRefreshAccountInfo

    var plusInfo: String = L10n.watchSourcePlusInfo

    private var refreshTimedActionHelper = TimedActionHelper()

    func handleDataUpdated() {
        guard !refreshTimedActionHelper.isTimerValid() else {
            refreshTimedActionHelper.cancelTimer()
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
            return
        }
        reload()
    }

    func willActivate() {

        //if let name = restoreName() {
        //    UserDefaults.standard.set(name, forKey: WatchConstants.UserDefaults.lastPage)
            //UserDefaults.standard.set(restoreContext(), forKey: WatchConstants.UserDefaults.lastContext)
        //}

        addAdditionalObservers()
        handleDataUpdated()
        //populateTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidUpdate), name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
        removeAllCustomObservers()
        customObservers.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notifications For Updates

    @objc private func dataDidUpdate() {
        DispatchQueue.main.async {
            self.handleDataUpdated()
        }
    }

    private var customObservers = [Notification.Name]()

    func addCustomObserver(_ name: Notification.Name, selector: Selector) {
        if containsObserver(name) { return } // we already have this one

        customObservers.append(name)

        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }

    func removeAllCustomObservers() {
        if customObservers.count == 0 { return }

        let notCenter = NotificationCenter.default
        for name in customObservers {
            notCenter.removeObserver(self, name: name, object: nil)
        }
        customObservers.removeAll()
    }

    private func containsObserver(_ name: Notification.Name) -> Bool {
        if customObservers.count == 0 { return false }

        return customObservers.contains(name)
    }

    func addAdditionalObservers() {
        addCustomObserver(Notification.Name(rawValue: WatchConstants.Notifications.loginStatusUpdated), selector: #selector(handleStatusChangeFromNotification))
        addCustomObserver(Notification.Name(rawValue: ServerNotifications.subscriptionStatusChanged.rawValue), selector: #selector(handleStatusChangeFromNotification))
        addCustomObserver(Notification.Name(rawValue: ServerNotifications.syncFailed.rawValue), selector: #selector(updateLastRefreshDetails))
        addCustomObserver(Notification.Name(rawValue: ServerNotifications.syncStarted.rawValue), selector: #selector(updateLastRefreshDetails))
        addCustomObserver(Notification.Name(rawValue: ServerNotifications.syncCompleted.rawValue), selector: #selector(updateLastRefreshDetails))
    }

    @objc private func handleStatusChangeFromNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.reload()
        }
    }

    private func reload() {
        let isPlusUser = SubscriptionHelper.hasActiveSubscription()
        //phoneNowPlayingImage.setHidden(!SourceManager.shared.isPhone())
        //watchNowPlayingIcon.setHidden(!SourceManager.shared.isWatch())

        //signedInLabel.setHidden(!SyncManager.isUserLoggedIn())
        //signInInfoGroup.setHidden(SyncManager.isUserLoggedIn())

        if SyncManager.isUserLoggedIn(), isPlusUser {
            usernameLabel = ServerSettings.syncingEmail() ?? ""

            profileImage = UIImage(named: "profile-plus")
            updateLastRefreshDetails()
            //infoLabel.setHidden(false)
            infoLabel = L10n.watchSourceMsg
            //refreshDataButton.setHidden(false)
            //refreshAccountButton.setHidden(true)
            //watchPlusOnlyGroup.setHidden(true)
            //plusMarketingGroup.setHidden(true)
        } else {
            if SyncManager.isUserLoggedIn() {
                usernameLabel = ServerSettings.syncingEmail() ?? ""
            } else {
                usernameLabel = L10n.signedOut
            }
            profileImage = UIImage(named: "profile-free")
            //infoLabel.setHidden(true)
            //lastRefreshLabel.setHidden(true)
            //refreshDataButton.setHidden(true)
            //refreshAccountButton.setHidden(false)
            //watchPlusOnlyGroup.setHidden(false)
            //plusMarketingGroup.setHidden(false)
        }
    }

    func phoneTapped() {
        if SourceManager.shared.isWatch(), !nowPlayingEpisodesMatchOnBothSources() {
            WatchSyncManager.shared.syncThenNotifyPhone(significantChange: true, syncRequired: true)
        }

        SourceManager.shared.setSource(newSource: .phone)
    }

    func watchTapped() {
        guard SubscriptionHelper.hasActiveSubscription() else { return }

        if SourceManager.shared.isPhone(), !nowPlayingEpisodesMatchOnBothSources() {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
        }
        SourceManager.shared.setSource(newSource: .watch)

    }

    private func nowPlayingEpisodesMatchOnBothSources() -> Bool {
        let watchCurrentEpisode = PlaybackManager.shared.currentEpisode()
        let phoneCurrentEpisode = WatchDataManager.playingEpisode()
        if watchCurrentEpisode?.uuid == phoneCurrentEpisode?.uuid {
            if watchCurrentEpisode?.playedUpTo == phoneCurrentEpisode?.playedUpTo {
                return true
            }
        }
        return false
    }

    func refreshDataTapped() {
        WKInterfaceDevice.current().play(.success)
        SessionManager.shared.requestData()

        refreshTimedActionHelper.startTimer(for: 5.seconds, action: {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        })

        lastRefreshLabel = L10n.refreshing
    }

    func refreshAccountTapped() {
        WKInterfaceDevice.current().play(.success)
        SyncManager.signout()
        WatchSyncManager.shared.loginAndRefreshIfRequired()
    }

    @objc private func updateLastRefreshDetails() {
        var lastRefreshText = String()
        if !ServerSettings.lastRefreshSucceeded() || !ServerSettings.lastSyncSucceeded() {
            lastRefreshText = !ServerSettings.lastRefreshSucceeded() ? L10n.refreshFailed : L10n.syncFailed
        } else if SyncManager.isFirstSyncInProgress() {
            lastRefreshText = L10n.syncing
        } else if SyncManager.isRefreshInProgress() {
            lastRefreshText = L10n.refreshing
        } else if let lastUpdateTime = ServerSettings.lastRefreshEndTime() {
            lastRefreshText = L10n.refreshPreviousRun(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
        } else {
            lastRefreshText = L10n.timeFormatNever
        }

        DispatchQueue.main.async { [weak self] in
            self?.lastRefreshLabel = lastRefreshText
            //self?.lastRefreshLabel.setHidden(false)
        }
    }
}
