import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit
import SwiftUI

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

    private enum TableRow { case kidsProfile, allStats, downloaded, starred, listeningHistory, help, uploadedFiles, endOfYearPrompt, bookmarks }

    @IBOutlet var profileTable: UITableView! {
        didSet {
            profileTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
            profileTable.register(EndOfYearPromptCell.self, forCellReuseIdentifier: endOfYearPromptCell)
            profileTable.register(KidsProfileBannerTableCell.self, forCellReuseIdentifier: KidsProfileBannerTableCell.identifier)
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
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: profileTable)
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
        addCustomObserver(EndOfYear.eoyEligibilityDidChange, selector: #selector(handleDataChangedNotification))

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
        showReferralsHintIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        refreshControl?.parentViewControllerDidDisappear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideReferralsHint()
    }

    override func handleThemeChanged() {
        updateRefreshFooterColors()
        updateReferralsColors()
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
        refreshTableData()
    }

    private func updateLastRefreshDetails() {
        if areReferralsAvailable {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: referralsButton)
            updateReferralsColors()
        } else {
            navigationItem.leftBarButtonItem = nil
        }

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
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableData[indexPath.section][indexPath.row]

        guard row != .endOfYearPrompt else {
            return tableView.dequeueReusableCell(withIdentifier: endOfYearPromptCell, for: indexPath) as! EndOfYearPromptCell
        }

        if row == .kidsProfile {
            let cell = tableView.dequeueReusableCell(withIdentifier: KidsProfileBannerTableCell.identifier, for: indexPath) as! KidsProfileBannerTableCell
            cell.onCloseButtonTap = { [weak self] cell in
                if let cell, let indexPath = tableView.indexPath(for: cell) {
                    self?.tableData[indexPath.section].remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
            cell.onRequestEarlyAccessTap = { [weak self] _ in
                let viewModel = KidsProfileSheetViewModel()
                let hostViewController = KidsProfileSheetHost(viewModel: viewModel)
                self?.present(hostViewController, animated: true)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellId, for: indexPath) as! TopLevelSettingsCell

        cell.settingsImage.tintColor = ThemeColor.primaryIcon01()
        cell.settingsLabel.setLetterSpacing(-0.01)
        cell.separatorInset = .zero

        switch row {
        case .kidsProfile:
            return KidsProfileBannerTableCell()
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
        case .help:
            cell.settingsImage.image = UIImage(named: "profile-help")
            cell.settingsLabel.text = L10n.settingsHelp
        case .endOfYearPrompt:
            return EndOfYearPromptCell()
        case .bookmarks:
            cell.settingsImage.image = UIImage(named: "bookmarks-profile")
            cell.settingsLabel.text = L10n.bookmarks
        }

        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = tableData[indexPath.section][indexPath.row]
        return row != .kidsProfile
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = tableData[indexPath.section][indexPath.row]
        if row == .kidsProfile {
            Analytics.track(.kidsProfileBannerSeen)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableData[indexPath.section][indexPath.row]

        if EndOfYear.isEligible && row == .endOfYearPrompt ||
            row == .kidsProfile {
            return UITableView.automaticDimension
        } else {
            return 70
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = tableData[indexPath.section][indexPath.row]
        switch row {
        case .kidsProfile:
            break
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
        case .help:
            let navController = SJUIUtils.navController(for: OnlineSupportController())
            present(navController, animated: true, completion: nil)
        case .endOfYearPrompt:
            Analytics.track(.endOfYearProfileCardTapped)
            EndOfYear().showStories(in: self, from: .profile)
        case .bookmarks:
            let bookmarksController = BookmarksProfileListController()
            navigationController?.pushViewController(bookmarksController, animated: true)
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

    private var tableData: [[ProfileViewController.TableRow]] = []

    private func refreshTableData() {
        var data: [[ProfileViewController.TableRow]]
        data = [[.allStats, .downloaded, .uploadedFiles, .starred, .bookmarks, .listeningHistory, .help]]

        if EndOfYear.isEligible {
            data[0].insert(.endOfYearPrompt, at: 0)
        }

        if FeatureFlag.kidsProfile.enabled && !Settings.shouldHideBanner {
            data[0].insert(.kidsProfile, at: 0)
        }

        tableData = data
        profileTable.reloadData()
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

    // MARK: - Referrals

    private var numberOfReferralsAvailable: Int = 3

    private var areReferralsAvailable: Bool {
        return FeatureFlag.referrals.enabled && SubscriptionHelper.hasActiveSubscription()
    }

    private let numberOfFreeDaysOffered: Int = 30

    private lazy var referralsBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.text = "\(numberOfReferralsAvailable)"
        label.textAlignment = .center
        label.layer.borderWidth = 1
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 8
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        return label
    }()

    private lazy var referralsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: ReferralsConstants.giftIcon), for: .normal)
        button.addTarget(self, action: #selector(referralsTapped), for: .touchUpInside)
        button.addSubview(referralsBadge)
        NSLayoutConstraint.activate(
            [
                button.widthAnchor.constraint(equalToConstant: ReferralsConstants.giftSize),
                button.heightAnchor.constraint(equalToConstant: ReferralsConstants.giftSize),
                referralsBadge.widthAnchor.constraint(equalToConstant: ReferralsConstants.giftBadgeSize),
                referralsBadge.heightAnchor.constraint(equalToConstant: ReferralsConstants.giftBadgeSize),
                referralsBadge.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: -ReferralsConstants.giftBadgeSize / 2),
                referralsBadge.topAnchor.constraint(equalTo: button.topAnchor, constant: -ReferralsConstants.giftBadgeSize / 4)
            ]
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = false
        button.bringSubviewToFront(referralsBadge)
        return button
    }()

    private func updateReferrals() {
        if numberOfReferralsAvailable > 0 {
            numberOfReferralsAvailable -= 1
        } else {
            numberOfReferralsAvailable = 3
        }
        referralsBadge.text = "\(numberOfReferralsAvailable)"
        referralsBadge.isHidden = numberOfReferralsAvailable == 0
    }

    private func updateReferralsColors() {
        referralsBadge.backgroundColor = ThemeColor.secondaryIcon01()
        referralsBadge.textColor = ThemeColor.secondaryUi01()
        referralsBadge.layer.borderColor = ThemeColor.secondaryUi01().cgColor
    }

    @objc private func referralsTapped() {
        hideReferralsHint()
        Settings.shouldShowReferralsTip = false
        let vc = ReferralSendPassVC(viewModel: ReferralSendPassModel(numberOfPasses: numberOfReferralsAvailable))
        present(vc, animated: true)
        updateReferrals()
    }

    private enum ReferralsConstants {
        static let giftIcon = "gift"
        static let giftSize = CGFloat(24)
        static let giftBadgeSize = CGFloat(16)
        static let defaultTipSize = CGSizeMake(300, 50)
    }

    private var referralsTipVC: UIViewController?

    private func showReferralsHintIfNeeded() {
        guard areReferralsAvailable, numberOfReferralsAvailable > 0, Settings.shouldShowReferralsTip else {
            return
        }
        let vc = makeReferralsHint()
        present(vc, animated: true, completion: nil)
        self.referralsTipVC = vc
    }

    private func hideReferralsHint() {
        self.referralsTipVC?.dismiss(animated: true)
    }

    private func makeReferralsHint() -> UIViewController {
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let tipView = TipView(title: L10n.referralsTipTitle(numberOfReferralsAvailable),
                              message: L10n.referralsTipMessage(numberOfFreeDaysOffered),
                              sizeChanged: { size in
            vc.preferredContentSize = size
        } ).setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = ReferralsConstants.defaultTipSize
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.sourceView = referralsButton
            popoverPresentationController.sourceRect = referralsButton.bounds
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
            popoverPresentationController.passthroughViews = [referralsButton, navigationController?.navigationBar, tabBarController?.tabBar, view].compactMap({$0})
        }
        return vc
    }

}

extension ProfileViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
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
