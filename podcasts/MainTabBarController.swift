import PocketCastsDataModel
import PocketCastsServer
import SafariServices
import UIKit
import Combine
import PocketCastsUtils

class MainTabBarController: UITabBarController, NavigationProtocol {
    enum Tab { case podcasts, filter, discover, profile, upNext }

    var tabs = [Tab]()

    let playPauseCommand = UIKeyCommand(title: L10n.keycommandPlayPause, action: #selector(handlePlayPauseKey), input: " ", modifierFlags: [])

    private lazy var endOfYear = EndOfYear()

    private lazy var profileTabBarItem = UITabBarItem(title: L10n.profile, image: UIImage(named: "profile_tab"), tag: tabs.firstIndex(of: .profile) ?? -1)


    /// The viewDidAppear can trigger more than once per lifecycle, setting this flag on the first did appear prevents use from prompting more than once per lifecycle. But still wait until the tab bar has appeared to do so.
    var viewDidAppearBefore: Bool = false

    /// Whether we're actively presenting the what's new
    var isShowingWhatsNew: Bool = false

    /// Displayed during database migrations
    var alert: ShiftyLoadingAlert?

    override func viewDidLoad() {
        super.viewDidLoad()

        if FeatureFlag.upNextOnTabBar.enabled {
            tabs = [.podcasts, .upNext, .filter, .discover]
        } else {
            tabs = [.podcasts, .filter, .discover, .profile]
        }

        var vcsInTab = [UIViewController]()

        let podcastsController = PodcastListViewController()
        podcastsController.tabBarItem = UITabBarItem(title: L10n.podcastsPlural, image: UIImage(named: "podcasts_tab"), tag: tabs.firstIndex(of: .podcasts)!)

        let filtersViewController = PlaylistsViewController()
        filtersViewController.tabBarItem = UITabBarItem(title: L10n.filters, image: UIImage(named: "filters_tab"), tag: tabs.firstIndex(of: .filter)!)

        let discoverViewController = DiscoverViewController(coordinator: DiscoverCoordinator())
        discoverViewController.tabBarItem = UITabBarItem(title: L10n.discover, image: UIImage(named: "discover_tab"), tag: tabs.firstIndex(of: .discover)!)

        if FeatureFlag.upNextOnTabBar.enabled {
            let upNextViewController = UpNextViewController(source: .tabBar, showDone: false)
            upNextViewController.tabBarItem = UITabBarItem(title: L10n.upNext, image: UIImage(named: "upnext"), tag: tabs.firstIndex(of: .upNext)!)
            vcsInTab = [podcastsController, upNextViewController, filtersViewController, discoverViewController]
        } else {
            let profileViewController = ProfileViewController()
            profileViewController.tabBarItem = profileTabBarItem
            vcsInTab = [podcastsController, filtersViewController, discoverViewController, profileViewController]
        }

        displayEndOfYearBadgeIfNeeded()

        viewControllers = vcsInTab.map { SJUIUtils.navController(for: $0) }
        selectedIndex = UserDefaults.standard.integer(forKey: Constants.UserDefaults.lastTabOpened)

        // Track the initial tab opened event
        trackTabOpened(tabs[selectedIndex], isInitial: true)

        NavigationManager.sharedManager.mainViewControllerDidLoad(controller: self)
        setupMiniPlayer()
        updateTabBarColor()
        setupKeyboardShortcuts()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textEditingDidStart), name: Constants.Notifications.textEditingDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textEditingDidEnd), name: Constants.Notifications.textEditingDidEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFollowSystemThemeTurnedOn), name: Constants.Notifications.followSystemThemeTurnedOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unhideNavBar), name: Constants.Notifications.unhideNavBarRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileSeen), name: Constants.Notifications.profileSeen, object: nil)

        observersForEndOfYearStats()
        addBookmarkCreatedToastHandler()
    }

    private var cancellables = Set<AnyCancellable>()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fireSystemThemeMayHaveChanged()
        checkSubscriptionStatusChanged()
        checkPromotionFinishedAcknowledged()
        checkWhatsNewAcknowledged()

        // Show any app launch announcements/prompts only once
        if !viewDidAppearBefore {
            showWhatsNewIfNeeded()
            showEndOfYearPromptIfNeeded()

            viewDidAppearBefore = true
        }

        showInitialOnboardingIfNeeded()

        updateDatabaseIndexes()
    }

    /// Update database indexes and delete unused columns
    /// This is outside of migrations and done just once
    /// because for larger databases it's very time consuming
    private func updateDatabaseIndexes() {
        guard !Settings.upgradedIndexes else {
            return
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }

            if DataManager.sharedManager.podcastCount() > 100 {
                self.presentLoader()
            }
            DataManager.sharedManager.cleanUp()
            self.dismissLoader()
            Settings.upgradedIndexes = true
        }
    }

    private func showInitialOnboardingIfNeeded() {
        // Show if the user is not logged in and has never seen the prompt before
        if SyncManager.isUserLoggedIn() || (Settings.shouldShowInitialOnboardingFlow == false && Settings.hasSeenInitialOnboardingBefore == true) {
            return
        }

        NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow, data: ["flow": OnboardingFlow.Flow.initialOnboarding])

        // Set the flag so the user won't see the on launch flow again
        Settings.shouldShowInitialOnboardingFlow = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        fireSystemThemeMayHaveChanged()
    }

    @objc func themeDidChange() {
        updateTabBarColor()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func setupMiniPlayer() {
        let miniPlayer = MiniPlayerViewController(nibName: "MiniPlayerViewController", bundle: nil)
        NavigationManager.sharedManager.miniPlayer = miniPlayer

        miniPlayer.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(miniPlayer.view, belowSubview: tabBar)

        NSLayoutConstraint.activate([
            miniPlayer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayer.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])

        miniPlayer.changeHeightTo(miniPlayer.desiredHeight())
    }

    // MARK: - UITabBarDelegate

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let tabIndex = item.tag
        if tabIndex == selectedIndex, let navController = selectedViewController as? UINavigationController, navController.visibleViewController == navController.viewControllers.first {
            // the user has tapped on a tab they are already at the root of, so trigger an action so we can handle this
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.tappedOnSelectedTab, object: tabIndex)
        }

        if tabIndex != selectedIndex {
            let tab = tabs[tabIndex]
            trackTabOpened(tab)
            AnalyticsHelper.tabSelected(tab: tab)
        }

        UserDefaults.standard.set(tabIndex, forKey: Constants.UserDefaults.lastTabOpened)
    }

    // MARK: - NavigationProtocol

    func showInSafariViewController(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let safariViewController = SFSafariViewController(with: url)
        topController().present(safariViewController, animated: true, completion: nil)
    }

    func navigateToPodcastList(_ animated: Bool) {
        if !switchToTab(.podcasts) { return }

        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: true)
        }
    }

    func navigateToFolder(_ folder: Folder, popToRootViewController: Bool = true) {
        guard let navController = selectedViewController as? UINavigationController else { return }

        if popToRootViewController {
            navController.popToRootViewController(animated: false)
        }

        let folderController = FolderViewController(folder: folder)
        navController.pushViewController(folderController, animated: true)
    }

    func navigateToPodcast(_ podcast: Podcast) {
        appDelegate()?.miniPlayer()?.closeUpNextAndFullPlayer(completion: { [weak self] in

            guard let strongSelf = self else { return }

            if let navController = strongSelf.selectedViewController as? UINavigationController {
                if let existingPodcastController = navController.topViewController as? PodcastViewController {
                    if let existingUuid = existingPodcastController.podcast?.uuid, existingUuid == podcast.uuid {
                        return // we're already on this podcast
                    } else {
                        navController.popViewController(animated: false)
                    }
                }

                let podcastController = PodcastViewController(podcast: podcast)
                navController.pushViewController(podcastController, animated: true)
            }
        })
    }

    func navigateToPodcastInfo(_ podcastInfo: PodcastInfo) {
        appDelegate()?.miniPlayer()?.closeUpNextAndFullPlayer(completion: { [weak self] in
            guard let navController = self?.selectedViewController as? UINavigationController else {
                return
            }

            navController.popToRootViewController(animated: false)
            let podcastController = PodcastViewController(podcastInfo: podcastInfo, existingImage: nil)
            navController.pushViewController(podcastController, animated: true)
        })
    }

    func navigateTo(podcast searchResult: PodcastFolderSearchResult) {
        if let navController = selectedViewController as? UINavigationController {
            let podcastController = PodcastViewController(podcastInfo: PodcastInfo(from: searchResult), existingImage: nil)
            navController.pushViewController(podcastController, animated: true)
        }
    }

    func navigateToEpisode(_ episodeUuid: String, podcastUuid: String?, timestamp: TimeInterval?) {
        if let navController = selectedViewController as? UINavigationController {
            navController.dismiss(animated: false, completion: nil)

            // I know it looks dodgy, but the episode card won't load properly if you just dismissed another view controller. Need to figure out the actual bug...but for now:
            // (before you ask, using the completion block doesn't work above, regardless of whether animated is true or false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5.seconds) {
                if EpisodeLoadingController.needsLoading(uuid: episodeUuid), let podcastUuid {
                    let episodeController = EpisodeLoadingController(episodeUuid: episodeUuid,
                                                                     podcastUuid: podcastUuid,
                                                                     timestamp: timestamp)

                    let nav = UINavigationController(rootViewController: episodeController)
                    nav.modalPresentationStyle = .formSheet
                    nav.isNavigationBarHidden = true

                    navController.present(nav, animated: true)
                } else {
                    let episodeController = EpisodeDetailViewController(episodeUuid: episodeUuid, source: .homeScreenWidget, timestamp: timestamp)
                    episodeController.modalPresentationStyle = .formSheet

                    navController.present(episodeController, animated: true)
                }
            }
        }
    }

    func navigateToDiscover(_ animated: Bool) {
        switchToTab(.discover)
    }

    func navigateToProfile(_ animated: Bool) {
        if FeatureFlag.upNextOnTabBar.enabled {
            switchToTab(.podcasts)
            if let index = tabs.firstIndex(of: .podcasts),
               let navController = viewControllers?[safe: index] as? UINavigationController,
               let podcastsViewController = navController.viewControllers[safe: 0] as? PodcastListViewController {
                podcastsViewController.showProfileController()
            }
        } else {
            switchToTab(.profile)
        }
    }

    func navigateToFilter(_ filter: EpisodeFilter, animated: Bool) {
        if !switchToTab(.filter) { return }

        if let index = tabs.firstIndex(of: .filter),
           let navController = viewControllers?[safe: index] as? UINavigationController,
           let filtersViewController = navController.viewControllers[safe: 0] as? PlaylistsViewController {
            filtersViewController.showFilter(filter)
        }
    }

    func navigateToEditFilter(_ filter: EpisodeFilter) {
        switchToTab(.filter)
    }

    func navigateToAddFilter() {
        switchToTab(.filter)
    }

    func navigateToAddCustom(_ url: URL) {
        appDelegate()?.miniPlayer()?.closeUpNextAndFullPlayer(completion: {
            self.switchToTab(.profile)

            if let navController = self.selectedViewController as? UINavigationController {
                if let existingUploadedViewController = (navController.viewControllers.last as? UploadedViewController) {
                    existingUploadedViewController.closeAllChildrenViewControllers()
                }
                navController.popToRootViewController(animated: false)

                let uploadedViewController = UploadedViewController()
                uploadedViewController.fileURL = url
                navController.pushViewController(uploadedViewController, animated: false)
            }
        })
    }

    func navigateToFiles() {
        switchToTab(.profile)

        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)

            let filesController = UploadedViewController()
            navController.pushViewController(filesController, animated: true)
        }
    }

    func showSubscriptionCancelledAcknowledge() {
        let cancelledVC = CancelledAcknowledgeViewController()
        let controller = view.window?.rootViewController
        controller?.present(SJUIUtils.popupNavController(for: cancelledVC), animated: true, completion: nil)
    }

    func showSubscriptionRequired(_ upgradeRootViewController: UIViewController, source: PlusUpgradeViewSource, context: OnboardingFlow.Context? = nil, flow: OnboardingFlow.Flow = .plusUpsell) {
        // If we're already presenting a view, then present from that view if possible
        let presentingController = presentedViewController ?? view.window?.rootViewController

        let controller = OnboardingFlow.shared.begin(flow: flow, source: source.rawValue, context: context)
        presentingController?.present(controller, animated: true, completion: nil)
    }

    func showPlusMarketingPage() {
        showInSafariViewController(urlString: ServerConstants.Urls.plusInfo)
    }

    func showPromotionPage(promoCode: String?) {
        switchToTab(.profile)
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)

            if let profileVC = navController.topViewController as? ProfileViewController {
                profileVC.presentedViewController?.dismiss(animated: true, completion: nil)
                profileVC.promoCode = promoCode
            }
        }
    }

    func showPromotionFinishedAcknowledge() {
        let promoFinishedVC = PromotionFinishedViewController()
        let controller = view.window?.rootViewController
        controller?.present(SJUIUtils.popupNavController(for: promoFinishedVC), animated: true, completion: nil)
    }

    func showPrivacyPolicy() {
        showInSafariViewController(urlString: ServerConstants.Urls.privacyPolicy)
    }

    func showTermsOfUse() {
        showInSafariViewController(urlString: ServerConstants.Urls.termsOfUse)
    }

    func showWhatsNew(whatsNewInfo: WhatsNewInfo) {
        guard let controller = view.window?.rootViewController else { return }

        let whatsNewVC = SJUIUtils.popupNavController(for: WhatsNewViewController(whatsNewInfo: whatsNewInfo))
        whatsNewVC.modalPresentationStyle = .formSheet

        if controller.presentedViewController != nil {
            controller.dismiss(animated: true) {
                controller.present(whatsNewVC, animated: true, completion: nil)
            }
        } else {
            controller.present(whatsNewVC, animated: true, completion: nil)
        }
    }

    func navigateToFilterTab() {
        switchToTab(.filter)
    }

    func showSettingsAppearance() {
        switchToTab(.profile)
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)

            navController.pushViewController(SettingsViewController(), animated: false)
            navController.pushViewController(AppearanceViewController(), animated: true)
        }
    }

    func showProfilePage() {
        switchToTab(.profile)

        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
        }
    }

    func showHeadphoneSettings() {
        let state = NavigationManager.sharedManager.miniPlayer?.playerOpenState

        // Dismiss any presented views if the player is not already open/dismissing since it will dismiss itself
        if state != .open, state != .animating {
            dismissPresentedViewController()
        }

        switchToTab(.profile)
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
            navController.pushViewController(SettingsViewController(), animated: false)
            navController.pushViewController(HeadphoneSettingsViewController(), animated: true)
        }
    }

    func showSupporterSignIn(podcastInfo: PodcastInfo) {
        let supporterVC = SupporterGratitudeViewController(podcastInfo: podcastInfo)
        let controller = view.window?.rootViewController
        controller?.present(SJUIUtils.popupNavController(for: supporterVC), animated: true, completion: nil)
    }

    func showSupporterSignIn(bundleUuid: String) {
        let supporterVC = SupporterGratitudeViewController(bundleUuid: bundleUuid)
        let controller = view.window?.rootViewController
        controller?.present(SJUIUtils.popupNavController(for: supporterVC), animated: true, completion: nil)
    }

    func showSupporterBundleDetails(bundleUuid: String?) {
        switchToTab(.profile)
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
            let supporterVC = SupporterContributionsViewController()
            supporterVC.bundleUuidToOpen = bundleUuid
            navController.pushViewController(AccountViewController(), animated: false)
            navController.pushViewController(supporterVC, animated: true)
        }
    }

    func showEndOfYearStories() {
        guard let presentedViewController else {
            endOfYear.showStories(in: self, from: .modal)
            return
        }

        presentedViewController.dismiss(animated: true) {
            self.endOfYear.showStories(in: self, from: .modal)
        }
    }

    func dismissPresentedViewController(completion: (() -> Void)? = nil) {
        presentedViewController?.dismiss(animated: true, completion: completion)
    }

    func showOnboardingFlow(flow: OnboardingFlow.Flow?) {
        let controller = OnboardingFlow.shared.begin(flow: flow ?? .initialOnboarding)
        guard let presentedViewController else {
            present(controller, animated: true)
            return
        }

        presentedViewController.dismiss(animated: true) {
            self.present(controller, animated: true)
        }
    }

    private func topController() -> UIViewController {
        var topController: UIViewController = self
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }

    @discardableResult
    private func switchToTab(_ tab: Tab) -> Bool {
        guard let miniPlayer = NavigationManager.sharedManager.miniPlayer else { return false }

        if miniPlayer.playerOpenState == .animating {
            return false // can't switch tabs while animating
        }

        if miniPlayer.playerOpenState == .open {
            miniPlayer.closeFullScreenPlayer()
        }

        selectedIndex = tabs.firstIndex(of: tab)!

        return true
    }

    // MARK: - End of Year

    @objc private func profileSeen() {
        profileTabBarItem.badgeValue = nil
        Settings.showBadgeForEndOfYear = false
    }

    func observersForEndOfYearStats() {
        guard FeatureFlag.endOfYear.enabled else {
            return
        }

        NotificationCenter.default.addObserver(forName: .userSignedIn, object: nil, queue: .main) { notification in
            self.endOfYear.resetStateIfNeeded()
        }

        // When the What's New is dismissed, check to see if we should also show the end of year prompt
        NotificationCenter.default.addObserver(forName: .whatsNewDismissed, object: nil, queue: .main) { _ in
            self.isShowingWhatsNew = false
            self.showEndOfYearPromptIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: .onboardingFlowDidDismiss, object: nil, queue: .main) { notification in
            self.endOfYear.showPromptBasedOnState(in: self)

            self.displayEndOfYearBadgeIfNeeded()
        }

        // If the requirement for EOY changes and registration is not required anymore
        // Show the modal
        NotificationCenter.default.addObserver(forName: .eoyRegistrationNotRequired, object: nil, queue: .main) { [weak self] _ in
            guard let self else {
                return
            }

            if self.presentedViewController == nil {
                self.endOfYear.showPrompt(in: self)
            }
        }
    }

    // MARK: - Orientation

    // we implement this here to lock all views (except presented modal VCs to portrait)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    // MARK: - End of Year

    private func updateTabBarColor() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.tabBarBackgroundColor()

        // Change badge colors
        [appearance.stackedLayoutAppearance,
         appearance.inlineLayoutAppearance,
         appearance.compactInlineLayoutAppearance]
            .forEach {
                $0.normal.badgeBackgroundColor = .clear
                $0.normal.badgeTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemRed]
            }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.unselectedItemTintColor = AppTheme.unselectedTabBarItemColor()
        tabBar.tintColor = AppTheme.tabBarItemTintColor()
    }

    private func displayEndOfYearBadgeIfNeeded() {
        if EndOfYear.isEligible, Settings.showBadgeForEndOfYear, !FeatureFlag.upNextOnTabBar.enabled {
            profileTabBarItem.badgeValue = "●"
        }
    }

    @objc private func willEnterForeground() {
        fireSystemThemeMayHaveChanged()
        checkSubscriptionStatusChanged()
    }

    private var lastNotifiedAboutDark: Bool?
    private func fireSystemThemeMayHaveChanged() {
        if !Settings.shouldFollowSystemTheme() { return } // if the user has turned this off, then ignore system theme changes

        let style = traitCollection.userInterfaceStyle

        let isDark = (style == .dark)
        if lastNotifiedAboutDark == nil || isDark != lastNotifiedAboutDark {
            lastNotifiedAboutDark = isDark
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.systemThemeMayHaveChanged, object: isDark)
        }
    }

    @objc private func unhideNavBar() {
        if let navController = selectedViewController as? UINavigationController {
            navController.setNavigationBarHidden(false, animated: true)
        }
    }

    @objc private func handleFollowSystemThemeTurnedOn() {
        lastNotifiedAboutDark = nil
        fireSystemThemeMayHaveChanged()
    }

    private func checkSubscriptionStatusChanged() {
        checkSubscriptionCancelledAcknowledgement()
    }

    private func checkSubscriptionCancelledAcknowledgement() {
        let renewing = SubscriptionHelper.hasRenewingSubscription()
        let cancelAcknowledged = Settings.subscriptionCancelledAcknowledged()
        let giftDays = SubscriptionHelper.subscriptionGiftDays()
        let timeToSubscriptionExpiry = SubscriptionHelper.timeToSubscriptionExpiry() ?? 0

        if !renewing, !cancelAcknowledged, giftDays == 0, timeToSubscriptionExpiry < 0 {
            NavigationManager.sharedManager.navigateTo(NavigationManager.subscriptionCancelledAcknowledgePageKey, data: nil)
        }
    }

    private func checkWhatsNewAcknowledged() {
        guard let whatsNewInfo = WhatsNewHelper.extractWhatsNewInfo(), whatsNewInfo.versionCode > Settings.whatsNewLastAcknowledged() else { return }

        if ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: whatsNewInfo.minOSVersion, minorVersion: 0, patchVersion: 0)) {
            NavigationManager.sharedManager.navigateTo(NavigationManager.showWhatsNewPageKey, data: [NavigationManager.whatsNewInfoKey: whatsNewInfo])
        } else {
            Settings.setWhatsNewLastAcknowledged(whatsNewInfo.versionCode)
        }
    }

    private func checkPromotionFinishedAcknowledged() {
        let promoFinishedAcknowledged = Settings.promotionFinishedAcknowledged()
        let giftDays = SubscriptionHelper.subscriptionGiftDays()
        let timeToSubscriptionExpiry = SubscriptionHelper.timeToSubscriptionExpiry() ?? 0
        if giftDays > 0, !promoFinishedAcknowledged, timeToSubscriptionExpiry < 0 { NavigationManager.sharedManager.navigateTo(NavigationManager.showPromotionFinishedPageKey, data: nil)
        }
    }

    // There are different areas of the app that relies on presenting VCs from the tab bar
    // However, sometimes the tab bar is already displaying the player.
    // This code simple checks if the tab bar is already presenting something and, if yes,
    // present the VC through the presentedViewController
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if FeatureFlag.newPlayerTransition.enabled, let presentedViewController, !presentedViewController.isBeingDismissed {
            presentedViewController.present(viewControllerToPresent, animated: flag, completion: completion)
            return
        }

        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            PlaybackManager.shared.restartSleepTimer()
        }
    }
}

// MARK: - Bookmarks

private extension MainTabBarController {
    // Shows a toast notification when a bookmark is created and we're not in the full screen player
    func addBookmarkCreatedToastHandler() {
        let bookmarkManager = PlaybackManager.shared.bookmarkManager

        bookmarkManager.onBookmarkCreated
            .receive(on: RunLoop.main)
            .filter { event in
                UIApplication.shared.applicationState == .active
                && !SceneHelper.isConnectedToCarPlay
                && NavigationManager.sharedManager.miniPlayer?.playerOpenState == .closed
            }
            .compactMap { event in
                bookmarkManager.bookmark(for: event.uuid)
            }
            .sink { [weak self] bookmark in
                self?.showToast(for: bookmark)
            }
            .store(in: &cancellables)
    }

    func showToast(for bookmark: Bookmark) {
        let bookmarkManager = PlaybackManager.shared.bookmarkManager

        let title = bookmark.title
        let message = title == L10n.bookmarkDefaultTitle ? L10n.bookmarkAdded : L10n.bookmarkAddedNotification(title)

        let action = Toast.Action(title: L10n.changeBookmarkTitle) { [weak self] in
            let controller = BookmarkEditTitleViewController(manager: bookmarkManager, bookmark: bookmark, state: .updating, onDismiss: { [weak self] updatedTitle, cancel in
                guard title != updatedTitle else { return }

                self?.handleBookmarkTitleUpdated(updatedTitle: updatedTitle)
            })

            controller.source = .headphones

            self?.presentFromRootController(controller)
        }

        Toast.show(message, actions: [action], theme: .playerTheme)
    }

    func handleBookmarkTitleUpdated(updatedTitle: String) {
        Toast.show(L10n.bookmarkUpdatedNotification(updatedTitle), actions: [
            .init(title: L10n.bookmarkAddedButtonTitle, action: { [weak self] in
                self?.showBookmarksInPlayer()
            })
        ], theme: .playerTheme)
    }

    func showBookmarksInPlayer() {
        dismissIfNeeded {
            NavigationManager.sharedManager.miniPlayer?.openFullScreenPlayer {
                NavigationManager.sharedManager.miniPlayer?.fullScreenPlayer?.scrollToBookmarks()
            }
        }
    }
}

// MARK: - Analytics

private extension MainTabBarController {
    /// Tracks when a tab is switched to.
    /// - Parameters:
    ///   - tab: Which tab we're switching to
    ///   - isInitial: Whether this is the tab that is being loaded on first launch
    func trackTabOpened(_ tab: Tab, isInitial: Bool = false) {
        let event: AnalyticsEvent
        switch tab {
        case .podcasts:
            event = .podcastsTabOpened
        case .filter:
            event = .filtersTabOpened
        case .discover:
            event = .discoverTabOpened
        case .profile:
            event = .profileTabOpened
        case .upNext:
            event = .upNextTabOpened
        }

        Analytics.track(event, properties: ["initial": isInitial])
    }
}

// MARK: - App Launch Prompts

private extension MainTabBarController {
    func showEndOfYearPromptIfNeeded() {
        // Only show the prompt if there isn't an active announcement flow
        guard !isShowingWhatsNew, AnnouncementFlow.current == .none else { return }

        endOfYear.showPromptBasedOnState(in: self)
    }

    func showWhatsNewIfNeeded() {
        guard let controller = view.window?.rootViewController else { return }

        if let whatsNewViewController = appDelegate()?.whatsNew.viewControllerToShow() {
            controller.present(whatsNewViewController, animated: true)
            isShowingWhatsNew = true
        }
    }
}
