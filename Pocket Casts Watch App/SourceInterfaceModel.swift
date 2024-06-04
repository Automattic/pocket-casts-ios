import PocketCastsServer
import PocketCastsUtils
import WatchKit

class SourceInterfaceModel: ObservableObject {

    var infoLabel: String = ""
    @Published var lastRefreshLabel: String = L10n.profileLastAppRefresh(L10n.timeFormatNever)

    @Published var isPlusUser: Bool = false

    @Published var isLoggedIn: Bool = false

    var watchTitle: String = L10n.watch

    var signedInLabel: String = ""

    @Published var profileImage: String = "profile-free"

    @Published var usernameLabel: String = L10n.signedOut

    var phoneSourceLabel: String = L10n.phone

    var phoneSourceSymbol: String = L10n.phone.sourceUnicode(isWatch: false)

    var watchSourceSymbol: String = L10n.watch.sourceUnicode(isWatch: true)

    var refreshDataLabel: String = L10n.watchSourceRefreshData

    var signInPrompt: String = L10n.watchSourceSignInInfo

    var refreshAccountLabel: String = L10n.watchSourceRefreshAccount

    var refreshAccountInfo: String = L10n.watchSourceRefreshAccountInfo

    var plusInfo: String = L10n.watchSourcePlusInfo

    private var refreshTimedActionHelper = TimedActionHelper()

    func willActivate() {
        reload()
        addAdditionalObservers()
        handleDataUpdated()
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidUpdate), name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
    }

    func handleDataUpdated() {
        guard !refreshTimedActionHelper.isTimerValid() else {
            refreshTimedActionHelper.cancelTimer()
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
            return
        }
        reload()
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
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        //phoneNowPlayingImage.setHidden(!SourceManager.shared.isPhone())
        //watchNowPlayingIcon.setHidden(!SourceManager.shared.isWatch())

        if isLoggedIn, isPlusUser {
            usernameLabel = ServerSettings.syncingEmail() ?? ""
            profileImage = "profile-plus"
            updateLastRefreshDetails()
            infoLabel = L10n.watchSourceMsg
        } else {
            if isLoggedIn {
                usernameLabel = ServerSettings.syncingEmail() ?? ""
            } else {
                usernameLabel = L10n.signedOut
            }
            profileImage = "profile-free"
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
        }
    }
}
