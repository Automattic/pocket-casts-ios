import BackgroundTasks
import Firebase
import FirebasePerformance
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class AppDelegate: UIResponder, UIApplicationDelegate {
    private static let initialRefreshDelay = 2.seconds
    private static let minTimeBetweenRefreshes = 5.minutes

    private let shortcutManager = ShortcutManager()
    private let badgeHelper = BadgeHelper()
    private let traceHandler = TraceHelper()

    @objc var backgroundSessionCompletionHandler: (() -> Void)?

    var window: UIWindow?
    var progressDialog: ShiftyLoadingAlert?
    var modalController: UINavigationController?

    lazy var lenticularFilter: LenticularFilter = .init()
    lazy var appLifecycleAnalytics = AppLifecycleAnalytics()

    private var backgroundSignOutListener: BackgroundSignOutListener?

    var whatsNew: WhatsNew?

    // MARK: - App Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureFirebase()
        TraceManager.shared.setup(handler: traceHandler)

        setupWhatsNew()

        setupSecrets()
        addAnalyticsObservers()
        setupAnalytics()
        appLifecycleAnalytics.checkApplicationInstalledOrUpgraded()

        let defaults = UserDefaults.standard

        // check to see that this app has a unique ID, if not create one
        let uniqueId = defaults.string(forKey: Constants.UserDefaults.appId)
        if uniqueId?.count ?? 0 < 1 {
            let uuid = UUID().uuidString
            defaults.set(uuid, forKey: Constants.UserDefaults.appId)
            defaults.synchronize()
        }

        GoogleCastManager.sharedManager.setup()

        SyncManager.shouldUseNewSettingsSync = FeatureFlag.settingsSync.enabled
        CacheServerHandler.newShowNotesEndpoint = FeatureFlag.newShowNotesEndpoint.enabled
        CacheServerHandler.episodeFeedArtwork = FeatureFlag.episodeFeedArtwork.enabled

        setupRoutes()

        ServerConfig.shared.syncDelegate = ServerSyncManager.shared
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared
        checkDefaults()

        NotificationsHelper.shared.handleAppLaunch()

        DispatchQueue.global().async { [weak self] in
            self?.postLaunchSetup()
            self?.checkIfRestoreCleanupRequired()
            ImageManager.sharedManager.updatePodcastImagesIfRequired()
            WidgetHelper.shared.cleanupAppGroupImages()
        }

        badgeHelper.setup()
        WatchManager.shared.setup()
        SiriShortcutsManager.shared.setup()
        shortcutManager.listenForShortcutChanges()

        setupBackgroundRefresh()

        IAPHelper.shared.setup(hasSubscription: SubscriptionHelper.hasActiveSubscription())

        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChanged), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideOverlays), name: Constants.Notifications.openingNonOverlayableWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showOverlays), name: Constants.Notifications.closedNonOverlayableWindow, object: nil)

        setupSignOutListener()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        handleEnterBackground()
    }

    func handleEnterBackground() {
        scheduleNextBackgroundRefresh()
        FileLog.shared.forceFlush()

        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaults.lastAppCloseDate)
        badgeHelper.updateBadge()

        appLifecycleAnalytics.didEnterBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        handleBecomeActive()
    }

    func handleBecomeActive() {
        setupSignOutListener()
        appLifecycleAnalytics.didBecomeActive()

        // give the network a few seconds to come up before refreshing, also only refresh if the last refresh was more than 5 minutes ago
        let lastUpdateTime = ServerSettings.lastRefreshEndTime()
        if DateUtil.hasEnoughTimePassed(since: lastUpdateTime, time: AppDelegate.minTimeBetweenRefreshes) {
            Timer.scheduledTimer(withTimeInterval: AppDelegate.initialRefreshDelay, repeats: false, block: { _ in
                RefreshManager.shared.refreshPodcasts()
            })
        } else {
            PodcastManager.shared.checkForPendingAndAutoDownloads()
            UserEpisodeManager.checkForPendingUploads()
        }
        PlaybackManager.shared.updateIdleTimer()
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
    }

    // This method will be invoked even if the application was launched or resumed because of the remote notification. The respective delegate methods will be invoked first. Note that this behavior is in contrast to application:didReceiveRemoteNotification:, which is not called in those cases, and which will not be invoked if this method is implemented.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RefreshManager.shared.refreshPodcasts(completion: { refreshFetchResult in
            completionHandler(self.convertRefreshResult(result: refreshFetchResult))
        })
        badgeHelper.updateBadge()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("") { $0 + String(format: "%02X", $1) }

        PodcastManager.shared.didReceiveToken(token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ServerSettings.removePushToken()
    }

    func application(_ application: UIApplication, didChangeStatusBarFrame oldStatusBarFrame: CGRect) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.statusBarHeightChanged)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        GoogleCastManager.sharedManager.teardown()
        RefreshManager.shared.cancelAllRefreshes()

        badgeHelper.teardown()
        shortcutManager.stopListeningForShortcutChanges()

        IAPHelper.shared.tearDown()
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    @objc func miniPlayer() -> MiniPlayerViewController? {
        NavigationManager.sharedManager.miniPlayer
    }

    func openEpisode(_ episodeUuid: String, from podcast: Podcast, timestamp: TimeInterval? = nil) {
        DispatchQueue.main.async {
            self.hideProgressDialog()

            guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else {
                // for some reason we can't find this episode, so open the podcast instead
                FileLog.shared.addMessage("Unable to find episode with uuid \(episodeUuid), opening podcast `\(podcast.title ?? "")` instead")
                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])

                return
            }

            #if !os(watchOS)
            if let time {
                let dataManager = DataManager.sharedManager
                // Save the playback time before we start playing so the player will jump to the correct starting time when it does load
                dataManager.saveEpisode(playedUpTo: timestamp, episode: episode, updateSyncFlag: false)
            }
            #endif
            NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid])
        }
    }

    func hideProgressDialog() {
        if Thread.current.isMainThread {
            progressDialog?.hideAlert(false)
            progressDialog = nil
        } else {
            DispatchQueue.main.async {
                self.progressDialog?.hideAlert(false)
                self.progressDialog = nil
            }
        }
    }

    func openPlayerWhenReadyFromExternalEvent() {
        guard miniPlayer()?.playerOpenState != .open, miniPlayer()?.playerOpenState != .animating else { return }

        // when opening from an external event, we need to give the app time to set itself up and launch. As dodgy as this is, it means waiting a bit before launching the player
        SwiftUtils.performAfterDelayOnMainThread(1.0, closure: {
            guard let miniPlayer = self.miniPlayer(), miniPlayer.playerOpenState != .animating, miniPlayer.playerOpenState != .open else { return }

            miniPlayer.openFullScreenPlayer()
        })
    }

    // MARK: - Event Handling

    private var overlayShouldBeHidden = false
    @objc private func hideOverlays() {
        overlayShouldBeHidden = true
        if lenticularFilter.isShowing() {
            lenticularFilter.hide()
        }
    }

    @objc private func showOverlays() {
        overlayShouldBeHidden = false
        if Theme.sharedTheme.activeTheme == .radioactive {
            lenticularFilter.show()
        }
    }

    @objc private func handleThemeChanged() {
        if Theme.sharedTheme.activeTheme == .radioactive, !overlayShouldBeHidden {
            lenticularFilter.show()
        } else {
            lenticularFilter.hide()
        }
    }

    private func setupBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.Values.refreshTaskId, using: nil) { task in
            FileLog.shared.addMessage("Background refresh called")
            self.handleAppRefresh(task: task)
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.Values.refreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30.minutes)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            FileLog.shared.addMessage("Could not schedule app refresh: \(error.localizedDescription)")
        }
    }

    private func handleAppRefresh(task: BGTask) {
        scheduleNextBackgroundRefresh()

        task.expirationHandler = {
            FileLog.shared.addMessage("Background refresh timed out")
        }

        RefreshManager.shared.refreshPodcasts(completion: { refreshFetchResult in
            task.setTaskCompleted(success: refreshFetchResult != .failed)
        })
        badgeHelper.updateBadge()
    }

    private func configureFirebase() {
        FirebaseApp.configure()

        // we user remote config for varies parameters in the app we want to be able to set remotely. Here we set the defaults, then fetch new ones
        let remoteConfig = RemoteConfig.remoteConfig()
        var remoteConfigDefaults = [
            Constants.RemoteParams.periodicSaveTimeMs: NSNumber(value: Constants.RemoteParams.periodicSaveTimeMsDefault),
            Constants.RemoteParams.episodeSearchDebounceMs: NSNumber(value: Constants.RemoteParams.episodeSearchDebounceMsDefault),
            Constants.RemoteParams.podcastSearchDebounceMs: NSNumber(value: Constants.RemoteParams.podcastSearchDebounceMsDefault),
            Constants.RemoteParams.customStorageLimitGB: NSNumber(value: Constants.RemoteParams.customStorageLimitGBDefault),
            Constants.RemoteParams.endOfYearRequireAccount: NSNumber(value: Constants.RemoteParams.endOfYearRequireAccountDefault),
            Constants.RemoteParams.effectsPlayerStrategy: NSNumber(value: Constants.RemoteParams.effectsPlayerStrategyDefault),
            Constants.RemoteParams.patronCloudStorageGB: NSNumber(value: Constants.RemoteParams.patronCloudStorageGBDefault),
            Constants.RemoteParams.addMissingEpisodes: NSNumber(value: Constants.RemoteParams.addMissingEpisodesDefault),
            Constants.RemoteParams.newPlayerTransition: NSNumber(value: Constants.RemoteParams.newPlayerTransitionDefault),
            Constants.RemoteParams.errorLogoutHandling: NSNumber(value: Constants.RemoteParams.errorLogoutHandlingDefault),
            Constants.RemoteParams.slumberStudiosPromoCode: NSString(string: Constants.RemoteParams.slumberStudiosPromoCodeDefault)
        ]
        FeatureFlag.allCases.filter { $0.remoteKey != nil }.forEach { flag in
            remoteConfigDefaults[flag.remoteKey!] = NSNumber(value: flag.default)
        }
        remoteConfig.setDefaults(remoteConfigDefaults)

        remoteConfig.fetch(withExpirationDuration: 2.hour) { [weak self] status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)

                self?.updateEndOfYearRemoteValue()
                self?.updateRemoteFeatureFlags()
                ServerConfig.avoidLogoutOnError = FeatureFlag.errorLogoutHandling.enabled
            }
        }
    }

    private func updateRemoteFeatureFlags() {
        guard BuildEnvironment.current != .debug else { return }
        do {
            if FeatureFlag.newPlayerTransition.enabled != Settings.newPlayerTransition {
                // If the player transition changes we dismiss the full screen player
                // Otherwise this might lead to crashes or weird behavior
                appDelegate()?.miniPlayer()?.closeFullScreenPlayer()
                try FeatureFlagOverrideStore().override(FeatureFlag.newPlayerTransition, withValue: Settings.newPlayerTransition)
            }

            if FeatureFlag.errorLogoutHandling.enabled != Settings.errorLogoutHandling {
                ServerConfig.avoidLogoutOnError = FeatureFlag.errorLogoutHandling.enabled
                try FeatureFlagOverrideStore().override(FeatureFlag.errorLogoutHandling, withValue: Settings.errorLogoutHandling)
            }

            SyncManager.shouldUseNewSettingsSync = FeatureFlag.settingsSync.enabled

            try FeatureFlagOverrideStore().override(FeatureFlag.slumber, withValue: Settings.slumberPromoCode?.isEmpty == false)

            try FeatureFlag.allCases.forEach { flag in
                if let remoteKey = flag.remoteKey {
                    let remoteValue = RemoteConfig.remoteConfig().configValue(forKey: remoteKey).boolValue
                    try FeatureFlagOverrideStore().override(flag, withValue: remoteValue)
                }
            }
        } catch {
            FileLog.shared.addMessage("Failed to set remote feature flag: \(error)")
        }
    }

    private func updateEndOfYearRemoteValue() {
        // Update if EOY requires an account to be seen
        EndOfYear.requireAccount = Settings.endOfYearRequireAccount
    }

    private func postLaunchSetup() {
        if !UserDefaults.standard.bool(forKey: "CreatedDefPlaylistsV2") {
            PlaylistManager.createDefaultFilters()
            UserDefaults.standard.set(true, forKey: "CreatedDefPlaylistsV2")
        }
        DownloadManager.shared.clearStuckDownloads()
    }

    private func checkIfRestoreCleanupRequired() {
        let dataManager = DataManager.sharedManager

        // find the oldest episode in our database listed as being downloaded
        let query = "episodeStatus = \(DownloadStatus.downloaded.rawValue) ORDER BY publishedDate ASC, addedDate ASC LIMIT 1"
        guard let oldestEpisode = dataManager.findEpisodeWhere(customWhere: query, arguments: nil), !oldestEpisode.downloaded(pathFinder: DownloadManager.shared) else { return }

        // if we get here then we have at least one episode that is listed as downloaded that's actually not, so we need to go through and check them all
        FileLog.shared.addMessage("Detected restore cleanup required")
        let allQuery = "episodeStatus = \(DownloadStatus.downloaded.rawValue)"
        let downloadedEpisodes = dataManager.findEpisodesWhere(customWhere: allQuery, arguments: nil)
        for episode in downloadedEpisodes {
            if !episode.downloaded(pathFinder: DownloadManager.shared) {
                // episode is listed as downloaded, but the file isn't there, fix this
                dataManager.saveEpisode(downloadStatus: .notDownloaded, episode: episode)
                dataManager.saveFrameCount(episode: episode, frameCount: 0)
            }
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)
    }

    private func convertRefreshResult(result: RefreshFetchResult) -> UIBackgroundFetchResult {
        switch result {
        case .failed:
            return UIBackgroundFetchResult.failed
        case .newData:
            return UIBackgroundFetchResult.newData
        case .noData:
            return UIBackgroundFetchResult.noData
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let role = connectingSceneSession.role

        if role == UISceneSession.Role.carTemplateApplication {
            return UISceneConfiguration(name: "Pocket Casts Car", sessionRole: UISceneSession.Role.carTemplateApplication)
        }

        return UISceneConfiguration(name: "Default Configuration", sessionRole: role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: Secrets

    private func setupSecrets() {
        ServerCredentials.sharing = ApiCredentials.sharingServerSecret
    }

    private func setupSignOutListener() {
        guard backgroundSignOutListener == nil else {
            return
        }

        backgroundSignOutListener = BackgroundSignOutListener(presentingViewController: SceneHelper.rootViewController())
    }

    // MARK: What's New

    private func setupWhatsNew() {
        whatsNew = WhatsNew()
    }
}
