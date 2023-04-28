import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class ProfileViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate enum StatValueType { case listened, saved }

    var refreshControl: PCRefreshControl?

    @IBOutlet weak var accountButton: AnimatedImageButton! {
        didSet {
            accountButton.mainColor = ThemeColor.primaryText02()
            accountButton.textColor = ThemeColor.primaryText01()
            accountButton.buttonTitle = SyncManager.isUserLoggedIn() ? L10n.account : L10n.setupAccount

            accountButton.buttonTapped = { [weak self] in
                self?.profileTapped()
            }
        }
    }

    @IBOutlet var emailAddress: UILabel! {
        didSet {
            emailAddress.font = .font(with: .body, weight: .semibold)
        }
    }

    @IBOutlet var profileStatusView: ProfileProgressCircleView! {
        didSet {
            profileStatusView.style = .primaryUi02

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
            profileStatusView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var podcastCount: ThemeableLabel! {
        didSet {
            podcastCount.style = .primaryText01
            podcastCount.font = .font(with: .body, weight: .bold)
        }
    }

    @IBOutlet var timeListened: ThemeableLabel! {
        didSet {
            timeListened.style = .primaryText01
            timeListened.font = .font(with: .body, weight: .bold)
        }
    }

    @IBOutlet var timeListenedUnits: ThemeableLabel! {
        didSet {
            timeListenedUnits.style = .primaryText01
            timeListenedUnits.font = .font(with: .caption2, weight: .semibold)
        }
    }

    @IBOutlet var hoursSaved: ThemeableLabel! {
        didSet {
            hoursSaved.style = .primaryText01
            hoursSaved.font = .font(with: .body, weight: .bold)
        }
    }

    @IBOutlet var hoursSavedUnits: ThemeableLabel! {
        didSet {
            hoursSavedUnits.style = .primaryText01
            hoursSavedUnits.font = .font(with: .caption2, weight: .semibold)
        }
    }

    @IBOutlet var podcastsLabel: ThemeableLabel! {
        didSet {
            podcastsLabel.style = .primaryText01
            podcastsLabel.text = L10n.podcastsPlural.uppercased()
            podcastsLabel.font = .font(with: .caption2, weight: .semibold)
        }
    }

    @IBOutlet var podcastCountView: UIStackView!
    @IBOutlet var timeListenedView: UIStackView!
    @IBOutlet var timeSavedView: UIStackView!

    @IBOutlet var headerView: UIView!

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
        addCustomObserver(Notification.Name.userLoginDidChange, selector: #selector(handleDataChangedNotification))

        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
        if promoRedeemedMessage != nil {
            updateDisplayedData()
            showPromotionRedeemedAcknowledgement()
            promoRedeemedMessage = nil
        }

        if EndOfYear.isEligible {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.profileSeen)
        }
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
        accountButton.mainColor = ThemeColor.primaryText02()
        accountButton.textColor = ThemeColor.primaryText01()
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

    @objc func profileTapped() {
        Analytics.track(.profileAccountButtonTapped)

        if SyncManager.isUserLoggedIn() {
            showAccountController()
        } else {
            showProfileSetupController()
        }
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
        if SyncManager.isUserLoggedIn(), let email = ServerSettings.syncingEmail() {
            emailAddress.text = email
            emailAddress.isHidden = false

            let totalListeningTime = StatsManager.shared.totalListeningTimeInclusive()
            let savedTime = StatsManager.shared.totalSkippedTimeInclusive() + StatsManager.shared.timeSavedVariableSpeedInclusive() + StatsManager.shared.timeSavedDynamicSpeedInclusive() + StatsManager.shared.totalAutoSkippedTimeInclusive()
            updateTimes(listenedTime: totalListeningTime, savedTime: savedTime)

            if SubscriptionHelper.hasActiveSubscription() {
                profileStatusView.isSubscribed = true

                var hideExpiryCountdown = true
                if let expiryTime = SubscriptionHelper.timeToSubscriptionExpiry() {
                    hideExpiryCountdown = expiryTime > Constants.Limits.maxSubscriptionExpirySeconds
                    profileStatusView.secondsTillExpiry = expiryTime
                }

                if !(SubscriptionHelper.hasRenewingSubscription() || hideExpiryCountdown) {
                    if let expiryDate = SubscriptionHelper.subscriptionRenewalDate(), expiryDate.timeIntervalSinceNow > 0 {
                        let time = (TimeFormatter.shared.appleStyleTillString(date: expiryDate) ?? "never").localizedUppercase
                        emailAddress.text = L10n.plusSubscriptionExpiration(time)
                    }
                }
            } else {
                profileStatusView.isSubscribed = false
            }
        } else {
            emailAddress.isHidden = true
            profileStatusView.isSubscribed = false
            let totalListeningTime = StatsManager.shared.totalListeningTime()
            let savedTime = StatsManager.shared.totalSkippedTime() + StatsManager.shared.timeSavedVariableSpeed() + StatsManager.shared.timeSavedDynamicSpeed() + StatsManager.shared.totalAutoSkippedTime()
            updateTimes(listenedTime: totalListeningTime, savedTime: savedTime)
        }

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

    private func updateTimes(listenedTime: TimeInterval, savedTime: TimeInterval) {
        let pcastCount = DataManager.sharedManager.podcastCount()
        podcastCount.text = "\(pcastCount)"
        podcastCountView.accessibilityLabel = L10n.podcastCount(pcastCount)

        updateTimeStat(valueLabel: timeListened, unitLabel: timeListenedUnits, value: listenedTime, valueType: .listened)
        timeListenedView.accessibilityLabel = timeListened.text! + timeListenedUnits.text!

        updateTimeStat(valueLabel: hoursSaved, unitLabel: hoursSavedUnits, value: savedTime, valueType: .saved)
        timeSavedView.accessibilityLabel = hoursSaved.text! + hoursSavedUnits.text!
    }

    private func updateTimeStat(valueLabel: UILabel, unitLabel: UILabel, value: TimeInterval, valueType: StatValueType) {
        let days = Int(safeDouble: value / 86400)
        let hours = Int(safeDouble: value / 3600) - (days * 24)
        let mins = Int(safeDouble: value / 60) - (hours * 60) - (days * 24 * 60)
        let secs = Int(safeDouble: value.truncatingRemainder(dividingBy: 60))

        if mins < 1, hours < 1, days < 1 {
            valueLabel.text = "\(secs)"
            unitLabel.text = valueType == .listened ? L10n.secondsListened : L10n.secondsSaved
        } else if days > 0 {
            valueLabel.text = "\(days)"
            if days == 1 {
                unitLabel.text = valueType == .listened ? L10n.dayListened : L10n.daySaved
            } else {
                unitLabel.text = valueType == .listened ? L10n.daysListened : L10n.daysSaved
            }
        } else if hours > 0 {
            valueLabel.text = "\(hours)"
            if hours == 1 {
                unitLabel.text = valueType == .listened ? L10n.hourListened : L10n.hourSaved
            } else {
                unitLabel.text = valueType == .listened ? L10n.hoursListened : L10n.hoursSaved
            }
        } else if mins > 0 {
            valueLabel.text = "\(mins)"
            if mins == 1 {
                unitLabel.text = valueType == .listened ? L10n.minuteListened : L10n.minuteSaved
            } else {
                unitLabel.text = valueType == .listened ? L10n.minutesListened : L10n.minutesSaved
            }
        }

        unitLabel.text = unitLabel.text?.uppercased()
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
        UITableView.automaticDimension
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
