import Combine
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class UploadedViewController: PCViewController, UserEpisodeDetailProtocol {
    private let episodesDataManager = EpisodesDataManager()
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var uploadsTable: ThemeableTable! {
        didSet {
            registerLongPress()
            uploadsTable.allowsMultipleSelectionDuringEditing = true
        }
    }

    @IBOutlet var noEpisodesScrollView: UIScrollView! {
        didSet {
            noEpisodesScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
        }
    }

    @IBOutlet var noFilesImage: ThemeableImageView! {
        didSet {
            noFilesImage.imageNameFunc = AppTheme.noFilesImageName
        }
    }

    @IBOutlet var noEpisodeTitleLabel: ThemeableLabel! {
        didSet {
            noEpisodeTitleLabel.style = .primaryText01
            noEpisodeTitleLabel.text = L10n.fileUploadNoFilesTitle
        }
    }

    @IBOutlet var noEpisodeDetailLabel: ThemeableLabel! {
        didSet {
            noEpisodeDetailLabel.style = .primaryText02
            noEpisodeDetailLabel.text = L10n.fileUploadNoFilesDescription
        }
    }

    @IBOutlet var howToBtn: ThemeableUIButton! {
        didSet {
            howToBtn.setTitle(L10n.fileUploadNoFilesHelper, for: .normal)
        }
    }

    @IBOutlet weak var addFilesButton: ThemeableRoundedButton! {
        didSet {
            addFilesButton.setTitle(L10n.fileUploadAddFile, for: .normal)
        }
    }

    var uploadedEpisodes = [UserEpisode]()
    let headerView = UploadedStorageHeaderView()

    private var tableRefreshControl: UploadedRefreshControl?
    private var noEpisodeRefreshControl: UploadedRefreshControl?
    var userEpisodeDetailVC: UserEpisodeDetailViewController?

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupNavBar()
                self.uploadsTable.beginUpdates()
                self.uploadsTable.setEditing(self.isMultiSelectEnabled, animated: true)
                self.insetAdjuster.isMultiSelectEnabled = self.isMultiSelectEnabled
                self.uploadsTable.endUpdates()

                if self.isMultiSelectEnabled {
                    Analytics.track(.uploadedFilesMultiSelectEntered)
                    self.multiSelectActionBar.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectActionBarBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.uploadsTable.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                } else {
                    Analytics.track(.uploadedFilesMultiSelectExited)
                    self.selectedEpisodes.removeAll()
                }
            }
        }
    }

    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
    @IBOutlet var multiSelectActionBar: MultiSelectFooterView! {
        didSet {
            multiSelectActionBar.delegate = self
            multiSelectActionBar.getActionsFunc = Settings.fileMultiSelectActions
            multiSelectActionBar.setActionsFunc = Settings.updateFilesMultiSelectActions
        }
    }

    @IBOutlet var multiSelectActionBarBottomConstraint: NSLayoutConstraint!

    var selectedEpisodes = [UserEpisode]() {
        didSet {
            multiSelectActionBar.setSelectedCount(count: selectedEpisodes.count)
            updateSelectAllBtn()
        }
    }

    // MARK: - View Methods

    override func viewDidLoad() {
        setupNavBar()
        setupAddFilesButton()
        super.viewDidLoad()

        registerCells()
        title = L10n.files

        if let navController = navigationController, SubscriptionHelper.hasActiveSubscription() {
            tableRefreshControl = UploadedRefreshControl(scrollView: uploadsTable, navBar: navController.navigationBar, source: .files)
            noEpisodeRefreshControl = UploadedRefreshControl(scrollView: noEpisodesScrollView, navBar: navController.navigationBar, source: .noFiles)
        }

        noEpisodesScrollView.alwaysBounceVertical = true

        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        headerView.controllerForPresenting = self
        uploadsTable.tableHeaderView = headerView
        updateHeaderView()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: uploadsTable)
        reloadLocalFiles()

        Analytics.track(.uploadedFilesShown)

        listenForChangedBookmarks()
    }

    var fileURL: URL?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableRefreshControl?.parentViewControllerDidAppear()
        noEpisodeRefreshControl?.parentViewControllerDidAppear()
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.shadowImage = nil

        reloadAllFiles()
        addUIObservers()

        if let fileURL = fileURL {
            let addCustomVC = AddCustomViewController(fileUrl: fileURL)

            present(SJUIUtils.popupNavController(for: addCustomVC), animated: true, completion: nil)
            self.fileURL = nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        tableRefreshControl?.parentViewControllerDidDisappear()
        noEpisodeRefreshControl?.parentViewControllerDidDisappear()
    }

    // MARK: - App Backgrounding

    override func handleAppWillBecomeActive() {
        reloadAllFiles()
        addUIObservers()
    }

    override func handleAppDidEnterBackground() {
        // we don't need to keep our UI up to date while backgrounded, so remove all the notification observers we have
        removeAllCustomObservers()
    }

    private func addUIObservers() {
        // TODO: a table diff might be more efficient here (and have nicer animations)

        addCustomObserver(ServerNotifications.userEpisodesRefreshed, selector: #selector(handleReloadFromNotification))
        addCustomObserver(ServerNotifications.userEpisodesRefreshFailed, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.userEpisodeDeleted, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(ServerNotifications.userEpisodeUploadStatusChanged, selector: #selector(uploadCompletedRefresh(notification:)))
    }

    func setupNavBar() {
        supportsGoogleCast = isMultiSelectEnabled ? false : true
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(menuTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilitySortAndOptions

        navigationItem.leftBarButtonItem = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .done, target: self, action: #selector(selectAllTapped)) : nil
        navigationItem.backBarButtonItem = isMultiSelectEnabled ? nil : UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    func setupAddFilesButton() {
        addFilesButton.shouldFill = false
    }

    @objc private func menuTapped(_ sender: UIBarButtonItem) {
        Analytics.track(.uploadedFilesOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let addFileAction = OptionAction(label: L10n.fileUploadAddFile, icon: "filter_add") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "add_file"])
            self?.addFilesTapped(UIButton())

        }
        optionsPicker.addAction(action: addFileAction)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let currentSort = UploadedSort(rawValue: Settings.userEpisodeSortBy())
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: currentSort?.description ?? "", icon: "podcastlist_sort") {
            self.showSortByPicker()
        }
        optionsPicker.addAction(action: sortAction)

        let settingsAction = OptionAction(label: L10n.settingsFiles, icon: "podcast-settings") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "files_settings"])
            self?.navigationController?.pushViewController(UploadedSettingsViewController(), animated: true)
        }
        optionsPicker.addAction(action: settingsAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    @objc private func handleReloadFromNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.reloadLocalFiles()
        }
    }

    func reloadLocalFiles() {
        uploadedEpisodes = episodesDataManager.uploadedEpisodes()
        uploadsTable.isHidden = (uploadedEpisodes.count == 0)

        uploadsTable.reloadData()
        updateHeaderView()
    }

    private func reloadAllFiles() {
        if SubscriptionHelper.hasActiveSubscription() {
            UserEpisodeManager.updateUserEpisodes()
        } else {
            reloadLocalFiles()
        }
    }

    @IBAction func howToTapped(_ sender: Any) {
        Analytics.track(.uploadedFilesHelpButtonTapped)

        let howToController = HowToUploadViewController()
        let navController = SJUIUtils.navController(for: howToController)
        present(navController, animated: true, completion: nil)
    }

    @IBAction func addFilesTapped(_ sender: Any) {
        Analytics.track(.uploadedFilesAddButtonTapped)

        //TODO: Add other supported content types
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.mp3], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .overFullScreen
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func showSortByPicker() {
        Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "sort_by"])

        let optionsPicker = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        UploadedSort.allCases.forEach { sort in
            optionsPicker.addAction(action: createSortAction(sort: sort))
        }

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    private func createSortAction(sort: UploadedSort) -> OptionAction {
        let action = OptionAction(label: sort.description, selected: sort.rawValue == Settings.userEpisodeSortBy()) {
            Settings.setUserEpisodeSortBy(sort.rawValue)
            Analytics.track(.uploadedFilesSortByChanged, properties: ["sort_order": sort])

            self.reloadLocalFiles()
        }

        return action
    }

    @objc func updateHeaderView() {
        headerView.update()
    }

    @objc func uploadCompletedRefresh(notification: Notification) {
        guard let episodeUuid = notification.object as? String, let episode = DataManager.sharedManager.findUserEpisode(uuid: episodeUuid), episode.uploaded() else {
            return
        }
        UserEpisodeManager.updateUserEpisodes()
    }

    // NARK :- UserEpisodeDetailViewControllerDelegate
    func showEdit(userEpisode: UserEpisode) {
        let editVC = AddCustomViewController(episode: userEpisode)
        navigationController?.pushViewController(editVC, animated: true)
    }

    func showDeleteConfirmation(userEpisode: UserEpisode) {
        UserEpisodeManager.presentDeleteOptions(episode: userEpisode, preferredStatusBarStyle: preferredStatusBarStyle, themeOverride: nil) { deletedLocal, deletedRemote in
            Analytics.track(.userFileDeleted, properties: ["local": deletedLocal, "remote": deletedRemote])

            if deletedRemote {
                self.removeFromUploadTable(userEpisode: userEpisode)
            }
            if deletedLocal {
                self.reloadLocalFiles()
            }
        }

        dismiss(animated: true, completion: nil)
    }

    func showUpgradeRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .files)
    }

    func userEpisodeDetailClosed() {
        userEpisodeDetailVC = nil
    }

    func closeAllChildrenViewControllers() {
        if let openAddFilesVC = presentedViewController?.children.first as? AddCustomViewController {
            openAddFilesVC.cancelTapped()
        }
        if let openUserEpiosdeDetails = userEpisodeDetailVC {
            openUserEpiosdeDetails.animateOut()
        }
    }

    private func removeFromUploadTable(userEpisode: UserEpisode) {
        guard let index = uploadedEpisodes.firstIndex(where: { $0.uuid == userEpisode.uuid }) else { return }
        uploadedEpisodes.remove(at: index)
        uploadsTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    // MARK: - UIScrollView

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let selectedRefreshControl: UploadedRefreshControl?
        if scrollView == noEpisodesScrollView {
            selectedRefreshControl = noEpisodeRefreshControl
        } else {
            selectedRefreshControl = tableRefreshControl
        }

        selectedRefreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let selectedRefreshControl: UploadedRefreshControl?
        if scrollView == noEpisodesScrollView {
            selectedRefreshControl = noEpisodeRefreshControl
        } else {
            selectedRefreshControl = tableRefreshControl
        }

        selectedRefreshControl?.scrollViewDidEndDragging(scrollView)
    }

    override func handleThemeChanged() {
        uploadsTable.reloadData()
    }
}

// MARK: - Analytics

extension UploadedViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .files
    }
}

private extension UploadedViewController {
    func listenForChangedBookmarks() {
        let manager = PlaybackManager.shared.bookmarkManager

        manager.onBookmarkCreated
            .filter { $0.podcast == nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleReloadFromNotification()
            }
            .store(in: &cancellables)

        manager.onBookmarksDeleted
            .filter { $0.items.first(where: { $0.podcast == nil }) != nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleReloadFromNotification()
            }
            .store(in: &cancellables)

        PaidFeature.bookmarks.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookmark in
                self?.handleReloadFromNotification()
            }
            .store(in: &cancellables)
    }
}

extension UploadedViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        let addCustomVC = AddCustomViewController(fileUrl: url)
        present(SJUIUtils.popupNavController(for: addCustomVC), animated: true, completion: nil)
    }
}
