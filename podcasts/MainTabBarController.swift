import PocketCastsDataModel
import PocketCastsServer
import SafariServices
import UIKit

class MainTabBarController: UITabBarController, NavigationProtocol {
    enum Tab { case podcasts, filter, discover, profile }

    let tabs: [Tab] = [.podcasts, .filter, .discover, .profile]

    let playPauseCommand = UIKeyCommand(title: L10n.keycommandPlayPause, action: #selector(handlePlayPauseKey), input: " ", modifierFlags: [])

    private lazy var endOfYear = EndOfYear()

    private lazy var profileTabBarItem = UITabBarItem(title: L10n.profile, image: UIImage(named: "profile_tab"), tag: tabs.firstIndex(of: .profile)!)

    override func viewDidLoad() {
        super.viewDidLoad()

        let podcastsController = PodcastListViewController()
        podcastsController.tabBarItem = UITabBarItem(title: L10n.podcastsPlural, image: UIImage(named: "podcasts_tab"), tag: tabs.firstIndex(of: .podcasts)!)

        let filtersViewController = PlaylistsViewController()
        filtersViewController.tabBarItem = UITabBarItem(title: L10n.filters, image: UIImage(named: "filters_tab"), tag: tabs.firstIndex(of: .filter)!)

        let discoverViewController = DiscoverViewController()
        discoverViewController.tabBarItem = UITabBarItem(title: L10n.discover, image: UIImage(named: "discover_tab"), tag: tabs.firstIndex(of: .discover)!)

        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = profileTabBarItem

        if EndOfYear.isEligible && Settings.showBadgeFor2022EndOfYear {
            profileTabBarItem.badgeValue = "●"
        }

        viewControllers = [podcastsController, filtersViewController, discoverViewController, profileViewController].map { SJUIUtils.navController(for: $0) }
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fireSystemThemeMayHaveChanged()
        checkSubscriptionStatusChanged()
        checkPromotionFinishedAcknowledged()
        checkWhatsNewAcknowledged()

        endOfYear.showPrompt(in: self)
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

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let safariViewController = SFSafariViewController(url: url, configuration: config)
        topController().present(safariViewController, animated: true, completion: nil)
    }

    func navigateToPodcastList(_ animated: Bool) {
        if !switchToTab(.podcasts) { return }

        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: true)
        }
    }

    func navigateToFolder(_ folder: Folder) {
        guard let navController = selectedViewController as? UINavigationController else { return }

        navController.popToRootViewController(animated: false)
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
        if !switchToTab(.podcasts) { return }

        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
            let podcastController = PodcastViewController(podcastInfo: podcastInfo, existingImage: nil)
            navController.pushViewController(podcastController, animated: false)
        }
    }

    func navigateToEpisode(_ episodeUuid: String) {
        if let navController = selectedViewController as? UINavigationController {
            navController.dismiss(animated: false, completion: nil)

            // I know it looks dodgy, but the episode card won't load properly if you just dismissed another view controller. Need to figure out the actual bug...but for now:
            // (before you ask, using the completion block doesn't work above, regardless of whether animated is true or false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5.seconds) {
                let episodeController = EpisodeDetailViewController(episodeUuid: episodeUuid, source: .homeScreenWidget)
                episodeController.modalPresentationStyle = .formSheet

                navController.present(episodeController, animated: true)
            }
        }
    }

    func navigateToDiscover(_ animated: Bool) {
        switchToTab(.discover)
    }

    func navigateToProfile(_ animated: Bool) {
        switchToTab(.profile)
    }

    func navigateToFilter(_ filter: EpisodeFilter, animated: Bool) {
        if !switchToTab(.filter) { return }

        if let navController = viewControllers?[safe: 1] as? UINavigationController, let filtersViewController = navController.viewControllers[safe: 0] as? PlaylistsViewController {
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

    func showSubscriptionRequired(_ upgradeRootViewController: UIViewController, source: PlusUpgradeViewSource) {
        // If we're already presenting a view, then present from that view if possible
        let controller = presentedViewController ?? view.window?.rootViewController
        let upgradeVC = UpgradeRequiredViewController(upgradeRootViewController: upgradeRootViewController, source: source)
        controller?.present(SJUIUtils.popupNavController(for: upgradeVC), animated: true, completion: nil)
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

    func showSignInPage() {
        switchToTab(.profile)
        guard !SyncManager.isUserLoggedIn() else { return }

        let signInController: UIViewController
        if FeatureFlag.signInWithApple {
            signInController = ProfileIntroViewController()
        }
        else {
            signInController = SyncSigninViewController()
            (signInController as! SyncSigninViewController).dismissOnCancel = true
        }

        let navController = SJUIUtils.popupNavController(for: signInController)
        present(navController, animated: true, completion: nil)
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
            endOfYear.showStories(in: self)
            return
        }

        presentedViewController.dismiss(animated: true) {
            self.endOfYear.showStories(in: self)
        }
    }

    func dismissPresentedViewController() {
        presentedViewController?.dismiss(animated: true)
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

    // MARK: - End of Year badge

    @objc private func profileSeen() {
        profileTabBarItem.badgeValue = nil
        Settings.showBadgeFor2022EndOfYear = false
    }

    // MARK: - Orientation

    // we implement this here to lock all views (except presented modal VCs to portrait)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func updateTabBarColor() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.tabBarBackgroundColor()

        if EndOfYear.isEligible {
            // Change badge colors
            [appearance.stackedLayoutAppearance,
             appearance.inlineLayoutAppearance,
             appearance.compactInlineLayoutAppearance]
                .forEach {
                    $0.normal.badgeBackgroundColor = .clear
                    $0.normal.badgeTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemRed]
                }
        }

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = AppTheme.tabBarBackgroundColor()
        }
        tabBar.unselectedItemTintColor = AppTheme.unselectedTabBarItemColor()
        tabBar.tintColor = AppTheme.tabBarItemTintColor()
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
        }

        Analytics.track(event, properties: ["initial": isInitial])
    }
}
