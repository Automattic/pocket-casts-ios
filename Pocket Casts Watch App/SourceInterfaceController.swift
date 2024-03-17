import PocketCastsServer
import PocketCastsUtils
import WatchKit

class SourceInterfaceController: PCInterfaceController {
    @IBOutlet var infoLabel: WKInterfaceLabel!
    @IBOutlet var refreshDataButton: WKInterfaceButton!
    @IBOutlet var lastRefreshLabel: WKInterfaceLabel!
    @IBOutlet var plusMarketingGroup: WKInterfaceGroup!

    @IBOutlet var phoneNowPlayingImage: WKInterfaceImage!

    @IBOutlet var watchPlusOnlyGroup: WKInterfaceGroup!
    @IBOutlet var watchNowPlayingIcon: WKInterfaceImage!
    @IBOutlet var watchTitle: WKInterfaceLabel! {
        didSet {
            watchTitle.setText(L10n.watch)
        }
    }

    @IBOutlet var signedInLabel: WKInterfaceLabel!
    @IBOutlet var profileImage: WKInterfaceImage!
    @IBOutlet var usernameLabel: WKInterfaceLabel!

    @IBOutlet var signInInfoGroup: WKInterfaceGroup!
    @IBOutlet var refreshAccountButton: WKInterfaceButton!

    @IBOutlet var phoneSourceLabel: WKInterfaceLabel! {
        didSet {
            phoneSourceLabel.setText(L10n.phone)
        }
    }

    @IBOutlet var phoneSourceSymbol: WKInterfaceLabel! {
        didSet {
            phoneSourceSymbol.setText(L10n.phone.sourceUnicode(isWatch: false))
        }
    }

    @IBOutlet var watchSourceSymbol: WKInterfaceLabel! {
        didSet {
            watchSourceSymbol.setText(L10n.watch.sourceUnicode(isWatch: true))
        }
    }

    @IBOutlet var refreshDataLabel: WKInterfaceLabel! {
        didSet {
            refreshDataLabel.setText(L10n.watchSourceRefreshData)
        }
    }

    @IBOutlet var signInPrompt: WKInterfaceLabel! {
        didSet {
            signInPrompt.setText(L10n.watchSourceSignInInfo)
        }
    }

    @IBOutlet var refreshAccountLabel: WKInterfaceLabel! {
        didSet {
            refreshAccountLabel.setText(L10n.watchSourceRefreshAccount)
        }
    }

    @IBOutlet var refreshAccountInfo: WKInterfaceLabel! {
        didSet {
            refreshAccountInfo.setText(L10n.watchSourceRefreshAccountInfo)
        }
    }

    @IBOutlet var plusInfo: WKInterfaceLabel! {
        didSet {
            plusInfo.setText(L10n.watchSourcePlusInfo)
        }
    }

    private var refreshTimedActionHelper = TimedActionHelper()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        reload()
    }

    override func handleDataUpdated() {
        guard !refreshTimedActionHelper.isTimerValid() else {
            refreshTimedActionHelper.cancelTimer()
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
            return
        }
        reload()
    }

    override func addAdditionalObservers() {
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
        phoneNowPlayingImage.setHidden(!SourceManager.shared.isPhone())
        watchNowPlayingIcon.setHidden(!SourceManager.shared.isWatch())

        signedInLabel.setHidden(!SyncManager.isUserLoggedIn())
        signInInfoGroup.setHidden(SyncManager.isUserLoggedIn())

        if SyncManager.isUserLoggedIn(), isPlusUser {
            usernameLabel.setText(ServerSettings.syncingEmail())

            profileImage.setImage(UIImage(named: "profile-plus"))
            updateLastRefreshDetails()
            infoLabel.setHidden(false)
            infoLabel.setText(L10n.watchSourceMsg)
            refreshDataButton.setHidden(false)
            refreshAccountButton.setHidden(true)
            watchPlusOnlyGroup.setHidden(true)

            plusMarketingGroup.setHidden(true)
        } else {
            if SyncManager.isUserLoggedIn() {
                usernameLabel.setText(ServerSettings.syncingEmail())
            } else {
                usernameLabel.setText(L10n.signedOut)
            }
            profileImage.setImage(UIImage(named: "profile-free"))
            infoLabel.setHidden(true)
            lastRefreshLabel.setHidden(true)
            refreshDataButton.setHidden(true)
            refreshAccountButton.setHidden(false)
            watchPlusOnlyGroup.setHidden(false)
            plusMarketingGroup.setHidden(false)
        }
    }

    @IBAction func phoneTapped() {
        if SourceManager.shared.isWatch(), !nowPlayingEpisodesMatchOnBothSources() {
            WatchSyncManager.shared.syncThenNotifyPhone(significantChange: true, syncRequired: true)
        }

        SourceManager.shared.setSource(newSource: .phone)

        pushController(withName: "InterfaceController", context: nil)
    }

    @IBAction func watchTapped() {
        guard SubscriptionHelper.hasActiveSubscription() else { return }

        if SourceManager.shared.isPhone(), !nowPlayingEpisodesMatchOnBothSources() {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: false)
        }
        SourceManager.shared.setSource(newSource: .watch)

        pushController(forType: .interface)
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

    @IBAction func refreshDataTapped() {
        WKInterfaceDevice.current().play(.success)
        SessionManager.shared.requestData()

        refreshTimedActionHelper.startTimer(for: 5.seconds, action: {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        })

        lastRefreshLabel.setText(L10n.refreshing)
    }

    @IBAction func refreshAccountTapped() {
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
            self?.lastRefreshLabel.setText(lastRefreshText)
            self?.lastRefreshLabel.setHidden(false)
        }
    }
}
