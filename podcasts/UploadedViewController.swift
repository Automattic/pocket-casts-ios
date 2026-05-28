import Combine
import SwiftUI
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
            uploadsTable.rowHeight = UITableView.automaticDimension
            uploadsTable.estimatedRowHeight = 80
            uploadsTable.sectionHeaderHeight = UITableView.automaticDimension
            uploadsTable.estimatedSectionHeaderHeight = 56
            uploadsTable.sectionHeaderTopPadding = 0
        }
    }

    var uploadedEpisodes = [UserEpisode]() {
        didSet {
            refreshContentUnavailable()
        }
    }
    let headerView = UploadedStorageHeaderView()

    private var tableRefreshController: UploadedFilesRefreshController?
    var userEpisodeDetailVC: UserEpisodeDetailViewController?

    private func refreshContentUnavailable() {
        var config: UIContentConfiguration?

        if uploadedEpisodes.isEmpty {
            let title = L10n.fileUploadNoFilesTitle
            let message = L10n.fileUploadNoFilesDescription
            config = ContentUnavailableConfiguration.emptyState(title: title, message: message, icon: { Image("profile_files") }, actions: [
                .init(title: L10n.fileUploadAddFile) {
                    self.addFile()
                },
                .init(id: L10n.fileUploadNoFilesHelper) {
                    Button(action: {
                        self.howTo()
                    }, label: {
                        Text(L10n.fileUploadNoFilesHelper)
                            .font(.body)
                    }).buttonStyle(SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01))
                }
            ])
        }

        if #available(iOS 17.0, *) {
            self.contentUnavailableConfiguration = config
        } else {
            self.setContentUnavailableConfiguration(config)
        }
    }

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.setupNavBar()
                self.setEnclosingTabBarHidden(self.isMultiSelectEnabled, animated: false)
                self.uploadsTable.beginUpdates()
                self.uploadsTable.setEditing(self.isMultiSelectEnabled, animated: true)
                self.insetAdjuster.isMultiSelectEnabled = self.isMultiSelectEnabled
                self.uploadsTable.endUpdates()

                if self.isMultiSelectEnabled {
                    Analytics.track(.uploadedFilesMultiSelectEntered)
                    self.multiSelectActionBar.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectActionBarBottomConstraint.constant = Constants.effectiveFooterViewPadding
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
        super.viewDidLoad()

        registerCells()
        title = L10n.files

        if SubscriptionHelper.hasActiveSubscription() {
            let controller = UploadedFilesRefreshController(source: .files)
            tableRefreshController = controller
            uploadsTable.refreshControl = controller.refreshControl
        }

        headerView.controllerForPresenting = self

        updateHeaderView()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: uploadsTable)
        reloadLocalFiles()

        Analytics.track(.uploadedFilesShown)

        listenForChangedBookmarks()
    }

    var fileURL: URL?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.shadowImage = nil

        reloadAllFiles()
        addUIObservers()

        if let fileURL {
            let addCustomVC = AddCustomViewController(fileUrl: fileURL)

            present(SJUIUtils.popupNavController(for: addCustomVC), animated: true, completion: nil)
            self.fileURL = nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
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
        addCustomObserver(Constants.Notifications.userEpisodeDeleted, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(handleReloadFromNotification))
        addCustomObserver(ServerNotifications.userEpisodeUploadStatusChanged, selector: #selector(uploadCompletedRefresh(notification:)))
    }

    func setupNavBar() {
        supportsGoogleCast = isMultiSelectEnabled ? false : true
        let rightButton = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(menuTapped))
        rightButton.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilitySortAndOptions
        super.setCustomRightBtn(rightButton, animated: true)

        navigationItem.setLeftBarButton(isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectAllTapped)) : nil, animated: true)
        navigationItem.setHidesBackButton(isMultiSelectEnabled, animated: true)
    }

    @objc private func menuTapped(_ sender: UIBarButtonItem) {
        Analytics.track(.uploadedFilesOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let addFileAction = OptionAction(label: L10n.fileUploadAddFile, icon: "filter_add") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "add_file"])
            self?.addFile()
        }
        optionsPicker.addAction(action: addFileAction)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let currentSort = UploadedSort(rawValue: Settings.userEpisodeSortBy())
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: currentSort?.description ?? "", icon: "podcastlist_sort") {
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "sort_by"])
        }
        sortAction.submenu = { [weak self] in self?.makeSortByPicker() }
        optionsPicker.addAction(action: sortAction)

        let settingsAction = OptionAction(label: L10n.settingsFiles, icon: "podcast-settings") { [weak self] in
            Analytics.track(.uploadedFilesOptionsModalOptionTapped, properties: ["option": "files_settings"])
            self?.navigationController?.pushViewController(UploadedSettingsViewController(), animated: true)
        }
        optionsPicker.addAction(action: settingsAction)

        optionsPicker.present(from: self)
    }

    @objc private func handleReloadFromNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.reloadLocalFiles()
        }
    }

    func reloadLocalFiles() {
        uploadedEpisodes = episodesDataManager.uploadedEpisodes()
        uploadsTable.isHidden = (uploadedEpisodes.isEmpty)

        uploadsTable.reloadData()
        updateHeaderView()
    }

    private func reloadAllFiles() {
        if SubscriptionHelper.hasActiveSubscription() {
            UserEpisodeManager.updateUserEpisodes()
            updateHeaderView()
        } else {
            reloadLocalFiles()
        }
    }

    func howTo() {
        Analytics.track(.uploadedFilesHelpButtonTapped)

        let howToView = HowToUploadView { [weak self] in self?.dismiss(animated: true) }.environmentObject(Theme.sharedTheme)
        let navController = SJUIUtils.navController(for: UIHostingController(rootView: howToView))
        present(navController, animated: true, completion: nil)
    }

    func addFile() {
        Analytics.track(.uploadedFilesAddButtonTapped)

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: FileTypeUtil.supportedUserFileTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .overFullScreen
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func makeSortByPicker() -> OptionsPicker {
        let optionsPicker = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        UploadedSort.allCases.forEach { sort in
            optionsPicker.addAction(action: createSortAction(sort: sort))
        }

        return optionsPicker
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
        Analytics.track(.userFileDeleteShown)
        UserEpisodeManager.presentDeleteOptions(episode: userEpisode, from: self, dismissCallback: {
            Analytics.track(.userFileDeleteDismissed)
        }) { deletedLocal, deletedRemote in
            Analytics.track(.userFileDeleted, properties: ["local": deletedLocal, "remote": deletedRemote])

            if deletedRemote {
                self.removeFromUploadTable(userEpisode: userEpisode)
            }
            if deletedLocal {
                self.reloadLocalFiles()
            }
        }
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
            .filter { $0.items.contains(where: { $0.podcast == nil }) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleReloadFromNotification()
            }
            .store(in: &cancellables)

        PaidFeature.bookmarks.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
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
