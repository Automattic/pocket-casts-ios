import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class ProfileViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate enum StatValueType { case listened, saved }

    var refreshControl: PCRefreshControl?

    @IBOutlet var footerView: UIView!
    @IBOutlet var alertIcon: UIImageView!
    @IBOutlet var lastRefreshTime: UILabel!
    @IBOutlet var refreshBtn: AnimatedImageButton! {
        didSet {
            refreshBtn.mainColor = ThemeColor.primaryText02()
            refreshBtn.buttonImage = UIImageView(image: UIImage(named: "profile-retry"))

            refreshBtn.buttonTapped = { [weak self] in
                self?.refreshTapped()
            }
        }
    }

    @IBOutlet var plusInfoView: PlusLockedInfoView! {
        didSet {
            plusInfoView.isHidden = Settings.plusInfoDismissedOnProfile() || SubscriptionHelper.hasActiveSubscription()
            plusInfoView.delegate = self
        }
    }

    var promoCode: String? {
        didSet {
            showPromotionViewController(promoCode: promoCode)
        }
    }

    var promoRedeemedMessage: String?
    private let settingsCellId = "SettingsCell"
    private let endOfYearPromptCell = "EndOfYearPromptCell"

    private enum TableRow { case allStats, downloaded, starred, listeningHistory, uploadedFiles, endOfYearPrompt }

    @IBOutlet var profileTable: UITableView! {
        didSet {
            profileTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
            profileTable.register(EndOfYearPromptCell.self, forCellReuseIdentifier: endOfYearPromptCell)
            profileTable.applyInsetForMiniPlayer()
        }
    }

    // MARK: - Profile Header
    private lazy var headerViewModel: ProfileHeaderViewModel = {
        let viewModel = ProfileHeaderViewModel(navigationController: navigationController)

        // Listen for view size changes and update the header view cell if needed
        viewModel.viewContentSizeChanged = { [weak self] in
            self?.profileTable.reloadData()
        }

        return viewModel
    }()

    private lazy var headerView: UIView = {
        let headerView = ProfileHeaderView(viewModel: headerViewModel)

        let view = headerView.themedUIView
        view.backgroundColor = .clear

        return view
    }()

    // MARK: - View Events

    override func viewDidLoad() {
        customRightBtn = UIBarButtonItem(image: UIImage(named: "profile-settings"), style: .plain, target: self, action: #selector(settingsTapped))
        customRightBtn?.accessibilityLabel = L10n.accessibilityProfileSettings
        customRightBtn?.accessibilityIdentifier = "Settings"

        super.viewDidLoad()
        navigationItem.title = L10n.profile

        profileTable.tableFooterView = footerView

        updateDisplayedData()
        updateRefreshFooterColors()
        updateFooterFrame()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateDisplayedData()

        Analytics.track(.profileShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshControl?.parentViewControllerDidAppear()

        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshComplete))
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(handleDataChangedNotification))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(handleDataChangedNotification))
        addCustomObserver(ServerNotifications.podcastRefreshFailed, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.podcastRefreshThrottled, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.syncCompleted, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.syncFailed, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(handleDataChangedNotification))
        addCustomObserver(.userLoginDidChange, selector: #selector(handleDataChangedNotification))
        addCustomObserver(.serverUserWillBeSignedOut, selector: #selector(handleDataChangedNotification))
        addCustomObserver(.whatsNewDismissed, selector: #selector(whatsNewDismissed))

        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
        if promoRedeemedMessage != nil {
            updateDisplayedData()
            showPromotionRedeemedAcknowledgement()
            promoRedeemedMessage = nil
        }

        if EndOfYear.isEligible {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.profileSeen)
        }

        whatsNewDismissed()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        refreshControl?.parentViewControllerDidDisappear()
    }

    override func handleThemeChanged() {
        updateRefreshFooterColors()
    }

    private func updateRefreshFooterColors() {
        refreshBtn.mainColor = ThemeColor.primaryText02()
        lastRefreshTime.textColor = ThemeColor.primaryText02()
        alertIcon.tintColor = ThemeColor.primaryIcon02()
    }

    // MARK: - Actions

    @objc private func checkForScrollTap(_ notification: Notification) {
        if let index = notification.object as? Int, index == tabBarItem.tag, profileTable.contentOffset.y > 0 {
            profileTable.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }

    @objc private func settingsTapped() {
        Analytics.track(.profileSettingsButtonTapped)

        let settingsController = SettingsViewController()
        navigationController?.pushViewController(settingsController, animated: true)
    }

    func showProfileSetupController() {
        if FeatureFlag.onboardingUpdates.enabled {
            NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow, data: ["flow": OnboardingFlow.Flow.loggedOut])
            return
        }

        let profileIntroController = ProfileIntroViewController()
        let navController = SJUIUtils.popupNavController(for: profileIntroController)
        present(navController, animated: true, completion: nil)
    }

    private func showAccountController() {
        let accountVC = AccountViewController()
        navigationController?.pushViewController(accountVC, animated: true)
    }

    private func refreshTapped() {
        Analytics.track(.profileRefreshButtonTapped)

        refreshBtn.animateImage(animationType: .rotate)
        lastRefreshTime.text = L10n.refreshing
        RefreshManager.shared.refreshPodcasts()
    }

    // MARK: - Data Updates

    @objc private func refreshComplete() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.refreshControl?.endRefreshing(true)
            self.refreshBtn.stopAnimatingImage()
            self.updateLastRefreshDetails()
        }
    }

    @objc private func handleDataChangedNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.updateDisplayedData()
        }
    }

    private func updateDisplayedData() {
        // Update the new header's data
        headerViewModel.update()

        updateLastRefreshDetails()
        plusInfoView.isHidden = Settings.plusInfoDismissedOnProfile() || SubscriptionHelper.hasActiveSubscription()
        updateFooterFrame()
        profileTable.reloadData()
    }

    private func updateLastRefreshDetails() {
        if !ServerSettings.lastRefreshSucceeded() || !ServerSettings.lastSyncSucceeded() {
            lastRefreshTime.text = !ServerSettings.lastRefreshSucceeded() ? L10n.refreshFailed : L10n.syncFailed
            refreshBtn.buttonTitle = L10n.tryAgain
            alertIcon.isHidden = false
        } else if let lastUpdateTime = ServerSettings.lastRefreshEndTime() {
            refreshBtn.buttonTitle = L10n.refreshNow
            if abs(lastUpdateTime.timeIntervalSinceNow) > 2.days {
                lastRefreshTime.text = L10n.profileLastAppRefresh(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
                alertIcon.isHidden = false
            } else {
                lastRefreshTime.text = L10n.refreshPreviousRun(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
                alertIcon.isHidden = true
            }
        } else {
            refreshBtn.buttonTitle = L10n.refreshNow
            lastRefreshTime.text = L10n.refreshPreviousRun(L10n.timeFormatNever)
            alertIcon.isHidden = false
        }
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData()[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableData()[indexPath.section][indexPath.row]

        guard row != .endOfYearPrompt else {
            return tableView.dequeueReusableCell(withIdentifier: endOfYearPromptCell, for: indexPath) as! EndOfYearPromptCell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellId, for: indexPath) as! TopLevelSettingsCell

        cell.settingsImage.tintColor = ThemeColor.primaryIcon01()
        cell.settingsLabel.setLetterSpacing(-0.01)
        switch row {
        case .allStats:
            cell.settingsImage.image = UIImage(named: "profile-stats")
            cell.settingsLabel.text = L10n.settingsStats
        case .downloaded:
            cell.settingsImage.image = UIImage(named: "profile-download")
            cell.settingsLabel.text = L10n.downloads
        case .uploadedFiles:
            cell.settingsImage.image = UIImage(named: "profile_files")
            cell.settingsLabel.text = L10n.files
        case .starred:
            cell.settingsImage.image = UIImage(named: "profile-star")
            cell.settingsLabel.text = L10n.statusStarred
        case .listeningHistory:
            cell.settingsImage.image = UIImage(named: "profile-history")
            cell.settingsLabel.text = L10n.listeningHistory
        case .endOfYearPrompt:
            return EndOfYearPromptCell()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if EndOfYear.isEligible && indexPath.row == 0 {
            return UITableView.automaticDimension
        } else {
            return 70
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = tableData()[indexPath.section][indexPath.row]
        switch row {
        case .allStats:
            let statsViewController = StatsViewController()
            navigationController?.pushViewController(statsViewController, animated: true)
        case .downloaded:
            let downloadController = DownloadsViewController()
            navigationController?.pushViewController(downloadController, animated: true)
        case .uploadedFiles:
            let uploadedController = UploadedViewController()
            navigationController?.pushViewController(uploadedController, animated: true)
        case .starred:
            let starredController = StarredViewController()
            navigationController?.pushViewController(starredController, animated: true)
        case .listeningHistory:
            let historyController = ListeningHistoryViewController()
            navigationController?.pushViewController(historyController, animated: true)
        case .endOfYearPrompt:
            Analytics.track(.endOfYearProfileCardTapped)
            EndOfYear().showStories(in: self, from: .profile)
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        18
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerViewModel.contentSize?.height ?? UITableView.automaticDimension
    }

    private func tableData() -> [[ProfileViewController.TableRow]] {
        var data: [[ProfileViewController.TableRow]]
        data = [[.allStats, .downloaded, .uploadedFiles, .starred, .listeningHistory]]

        if EndOfYear.isEligible {
            data[0].insert(.endOfYearPrompt, at: 0)
        }

        return data
    }

    private func updateFooterFrame() {
        let height: CGFloat = plusInfoView.isHidden ? 120 : 308
        footerView.frame = CGRect(x: footerView.frame.minX, y: footerView.frame.minY, width: footerView.frame.width, height: height)
    }

    // MARK: - What's New Autoplay flow

    @objc private func whatsNewDismissed() {
        showGeneralSettingsIfNeeded()
        showHeadphoneControlsFromWhatsNew()
    }

    private func showGeneralSettingsIfNeeded() {
        if AnnouncementFlow.current == .autoPlay {
            let generalSettingsViewController = GeneralSettingsViewController()
            navigationController?.pushViewController(generalSettingsViewController, animated: true)
        }
    }

    // Pushes to the headphone controls if shown from the what's new
    private func showHeadphoneControlsFromWhatsNew() {
        guard AnnouncementFlow.current == .bookmarksProfile else { return }

        let controller = HeadphoneSettingsViewController()
        navigationController?.pushViewController(controller, animated: true)
        AnnouncementFlow.current = .none
    }
}

// MARK: - PlusLockedInfoDelegate

extension ProfileViewController: PlusLockedInfoDelegate {
    func closeInfoTapped() {
        Settings.setPlusInfoDismissedOnProfile(true)
        plusInfoView.isHidden = true
        updateFooterFrame()
    }

    var displayingViewController: UIViewController {
        self
    }

    var displaySource: PlusUpgradeViewSource {
        .profile
    }
}

// MARK: - Refresh Control

extension ProfileViewController {
    private func setupRefreshControl() {
        guard let navController = navigationController else {
            return
        }

        refreshControl = PCRefreshControl(scrollView: profileTable,
                                          navBar: navController.navigationBar,
                                          source: .profile)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshControl?.scrollViewDidEndDragging(scrollView)
    }
}
