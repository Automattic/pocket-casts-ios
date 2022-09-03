import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class ProfileViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate enum StatValueType { case listened, saved }

    @IBOutlet var signedInView: ThemeableView! {
        didSet {
            signedInView.style = .primaryUi02
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
            signedInView.addGestureRecognizer(tapGesture)
        }
    }
    
    @IBOutlet var emailAddress: UILabel!
    @IBOutlet var signInStatus: ThemeableLabel! {
        didSet {
            signInStatus.style = .primaryText02
        }
    }
    
    @IBOutlet var disclosureImage: UIImageView! {
        didSet {
            disclosureImage.tintColor = ThemeColor.primaryIcon02()
        }
    }
    
    @IBOutlet var profileStatusView: ProfileProgressCircleView! {
        didSet {
            profileStatusView.style = .primaryUi02
        }
    }
    
    @IBOutlet var podcastCount: ThemeableLabel! {
        didSet {
            podcastCount.style = .contrast01
        }
    }
    
    @IBOutlet var timeListened: ThemeableLabel! {
        didSet {
            timeListened.style = .contrast01
        }
    }
    
    @IBOutlet var timeListenedUnits: ThemeableLabel! {
        didSet {
            timeListenedUnits.style = .contrast03
        }
    }
    
    @IBOutlet var hoursSaved: ThemeableLabel! {
        didSet {
            hoursSaved.style = .contrast01
        }
    }
    
    @IBOutlet var hoursSavedUnits: ThemeableLabel! {
        didSet {
            hoursSavedUnits.style = .contrast03
        }
    }
    
    @IBOutlet var podcastsLabel: ThemeableLabel! {
        didSet {
            podcastsLabel.style = .contrast03
            podcastsLabel.text = L10n.podcastsPlural
        }
    }
    
    @IBOutlet var podcastCountView: UIView!
    @IBOutlet var timeListenedView: UIView!
    @IBOutlet var timeSavedView: UIView!
    
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
    
    @IBOutlet var bgImage: UIImageView! {
        didSet {
            bgImage.kf.setImage(with: ServerHelper.asUrl(ServerConstants.Urls.image() + "trending/640/trending_bg.jpg"), placeholder: nil, options: [.transition(.fade(Constants.Animation.defaultAnimationTime))])
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
    
    private enum TableRow { case allStats, downloaded, starred, listeningHistory, uploadedFiles }
    
    @IBOutlet var profileTable: UITableView! {
        didSet {
            profileTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
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
        
        profileTable.tableHeaderView = headerView
        profileTable.tableFooterView = footerView
        
        updateDisplayedData()
        updateRefreshFooterColors()
        updateFooterFrame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateDisplayedData()

        Analytics.track(.profileShown)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshComplete))
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(handleDataChangedNotification))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(handleDataChangedNotification))
        addCustomObserver(ServerNotifications.podcastRefreshFailed, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.podcastRefreshThrottled, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.syncCompleted, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.syncFailed, selector: #selector(refreshComplete))
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(handleDataChangedNotification))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
        if promoRedeemedMessage != nil {
            updateDisplayedData()
            showPromotionRedeemedAcknowledgement()
            promoRedeemedMessage = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
    }
    
    override func handleThemeChanged() {
        updateRefreshFooterColors()
        disclosureImage.tintColor = ThemeColor.primaryIcon02()
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
    
    @objc func profileTapped() {
        Analytics.track(.profileAccountButtonTapped)

        if SyncManager.isUserLoggedIn() {
            showAccountController()
        }
        else {
            showProfileSetupController()
        }
    }
    
    func showProfileSetupController() {
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
                
                if SubscriptionHelper.hasRenewingSubscription() || hideExpiryCountdown {
                    signInStatus.text = L10n.pocketCastsPlus.uppercased()
                    signInStatus.textColor = ThemeColor.primaryText02()
                }
                else {
                    if let expiryDate = SubscriptionHelper.subscriptionRenewalDate(), expiryDate.timeIntervalSinceNow > 0 {
                        let time = (TimeFormatter.shared.appleStyleTillString(date: expiryDate) ?? "never").localizedUppercase
                        signInStatus.text = L10n.plusSubscriptionExpiration(time)
                    }
                    else {
                        signInStatus.text = L10n.pocketCastsPlus.uppercased()
                    }
                    signInStatus.textColor = AppTheme.pcPlusRed()
                }
            }
            else {
                signInStatus.text = L10n.signedInAs
                signInStatus.textColor = ThemeColor.primaryText02()
                profileStatusView.isSubscribed = false
            }
        }
        else {
            signInStatus.text = L10n.signedOut.localizedUppercase
            signInStatus.textColor = ThemeColor.primaryText02()
            emailAddress.text = L10n.setupAccount
            profileStatusView.isSubscribed = false
            let totalListeningTime = StatsManager.shared.totalListeningTime()
            let savedTime = StatsManager.shared.totalSkippedTime() + StatsManager.shared.timeSavedVariableSpeed() + StatsManager.shared.timeSavedDynamicSpeed() + StatsManager.shared.totalAutoSkippedTime()
            updateTimes(listenedTime: totalListeningTime, savedTime: savedTime)
        }
        
        signedInView.accessibilityLabel = signInStatus.text
        signedInView.accessibilityHint = L10n.accessibilitySignIn
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
        }
        else if let lastUpdateTime = ServerSettings.lastRefreshEndTime() {
            refreshBtn.buttonTitle = L10n.refreshNow
            if abs(lastUpdateTime.timeIntervalSinceNow) > 2.days {
                lastRefreshTime.text = L10n.profileLastAppRefresh(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
                alertIcon.isHidden = false
            }
            else {
                lastRefreshTime.text = L10n.refreshPreviousRun(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
                alertIcon.isHidden = true
            }
        }
        else {
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
        }
        else if days > 0 {
            valueLabel.text = "\(days)"
            if days == 1 {
                unitLabel.text = valueType == .listened ? L10n.dayListened : L10n.daySaved
            }
            else {
                unitLabel.text = valueType == .listened ? L10n.daysListened : L10n.daysSaved
            }
        }
        else if hours > 0 {
            valueLabel.text = "\(hours)"
            if hours == 1 {
                unitLabel.text = valueType == .listened ? L10n.hourListened : L10n.hourSaved
            }
            else {
                unitLabel.text = valueType == .listened ? L10n.hoursListened : L10n.hoursSaved
            }
        }
        else if mins > 0 {
            valueLabel.text = "\(mins)"
            if mins == 1 {
                unitLabel.text = valueType == .listened ? L10n.minuteListened : L10n.minuteSaved
            }
            else {
                unitLabel.text = valueType == .listened ? L10n.minutesListened : L10n.minutesSaved
            }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellId, for: indexPath) as! TopLevelSettingsCell
        
        cell.settingsImage.tintColor = ThemeColor.primaryIcon01()
        cell.settingsLabel.setLetterSpacing(-0.01)
        let row = tableData()[indexPath.section][indexPath.row]
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
        }
        
        return cell
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
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        18
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        1
    }
    
    private func tableData() -> [[ProfileViewController.TableRow]] {
        if !SyncManager.isUserLoggedIn() {
            return [[.allStats, .downloaded, .uploadedFiles, .listeningHistory]]
        }
        else {
            return [[.allStats, .downloaded, .uploadedFiles, .starred, .listeningHistory]]
        }
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
