import DifferenceKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class ListeningHistoryViewController: PCViewController {
    var episodes = [ArraySection<String, ListEpisode>]() {
        didSet {
            refreshContentUnavailable()
        }
    }
    var tempEpisodes = [ArraySection<String, ListEpisode>]() {
        didSet {
            refreshContentUnavailable()
        }
    }
    private let operationQueue = OperationQueue()
    var cellHeights: [IndexPath: CGFloat] = [:]

    private let episodesDataManager = EpisodesDataManager()
    private var searchController: PCSearchBarController?

    lazy private var informationalBannerCoordinator: InformationalBannerViewCoordinator = {
        let viewModel = InformationalBannerViewModel(bannerType: .listeningHistory)
        return InformationalBannerViewCoordinator(viewModel: viewModel)
    }()

    @IBOutlet var listeningHistoryTable: ThemeableTable! {
        didSet {
            registerCells()
            listeningHistoryTable.estimatedRowHeight = 80
            listeningHistoryTable.rowHeight = UITableView.automaticDimension
            listeningHistoryTable.allowsMultipleSelection = true
            listeningHistoryTable.allowsMultipleSelectionDuringEditing = true
            registerLongPress()
        }
    }

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupNavBar()
                self.listeningHistoryTable.beginUpdates()
                self.listeningHistoryTable.setEditing(self.isMultiSelectEnabled, animated: true)
                self.listeningHistoryTable.endUpdates()
                self.insetAdjuster.isMultiSelectEnabled = isMultiSelectEnabled
                if self.isMultiSelectEnabled {
                    Analytics.track(.listeningHistoryMultiSelectEntered)
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.listeningHistoryTable.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                } else {
                    Analytics.track(.listeningHistoryMultiSelectExited)
                    self.selectedEpisodes.removeAll()
                }
            }
        }
    }

    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
    @IBOutlet var multiSelectFooter: MultiSelectFooterView! {
        didSet {
            multiSelectFooter.delegate = self
            multiSelectFooter.getActionsFunc = Settings.listeningHistoryMultiSelectActions
            multiSelectFooter.setActionsFunc = Settings.updateListeningHistoryMultiSelectActions
        }
    }

    @IBOutlet var multiSelectFooterBottomConstraint: NSLayoutConstraint!

    var selectedEpisodes = [ListEpisode]() {
        didSet {
            multiSelectFooter.setSelectedCount(count: selectedEpisodes.count)
            updateSelectAllBtn()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if FeatureFlag.listeningHistorySearch.enabled {
            setupSearchController()
        }

        operationQueue.maxConcurrentOperationCount = 1
        title = L10n.listeningHistory
        refreshEpisodes(animated: false)

        setupNavBar()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: listeningHistoryTable)
        Analytics.track(.listeningHistoryShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupInformationalBanner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.listeningHistoryChanged, selector: #selector(refreshEpisodesFromNotification))
    }

    @objc private func refreshEpisodesFromNotification() {
        refreshEpisodes(animated: true)
    }

    @objc private func upNextChanged() {
        listeningHistoryTable.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func handleThemeChanged() {
        listeningHistoryTable.reloadData()
    }

    func refreshEpisodes(animated: Bool) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }

            let oldData = self.episodes
            let newData = self.episodesDataManager.listeningHistoryEpisodes()

            DispatchQueue.main.sync {
                if animated {
                    let changeSet = StagedChangeset(source: oldData, target: newData)
                    self.listeningHistoryTable.reload(using: changeSet, with: .none, setData: { data in
                        self.episodes = data
                    })
                } else {
                    self.episodes = newData
                    self.listeningHistoryTable.reloadData()
                }
            }
        }
    }

    @objc func clearTapped() {
        let optionPicker = OptionsPicker(title: "")
        let clearAllAction = OptionAction(label: L10n.historyClearAll, icon: nil, action: {
            Analytics.track(.listeningHistoryCleared)
            DataManager.sharedManager.clearAllEpisodePlayInteractions()
            if SyncManager.isUserLoggedIn() { ServerSettings.setLastClearHistoryDate(Date()) }
            self.refreshEpisodes(animated: true)

        })
        optionPicker.setNoActionCallback {
            Analytics.track(.listeningHistoryClearConfirmationDismissed)
        }
        optionPicker.addDescriptiveActions(title: L10n.historyClearAllDetails, message: L10n.historyClearAllDetailsMsg, icon: "option-cleanup", actions: [clearAllAction])
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
        Analytics.track(.listeningHistoryClearConfirmationShown)
    }

    func setupNavBar() {
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(menuTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilityMoreActions

        navigationItem.leftBarButtonItem = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .done, target: self, action: #selector(selectAllTapped)) : nil
        navigationItem.backBarButtonItem = isMultiSelectEnabled ? nil : UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    @objc private func menuTapped(_ sender: UIBarButtonItem) {
        Analytics.track(.listeningHistoryOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.listeningHistoryOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let clearAction = OptionAction(label: L10n.historyClearAllDetails, icon: "option-cleanup") { [weak self] in
            Analytics.track(.listeningHistoryOptionsModalOptionTapped, properties: ["option": "clear_history"])
            self?.clearTapped()
        }
        optionsPicker.addAction(action: clearAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func setupInformationalBanner() {
        if !informationalBannerCoordinator.shouldShowBanner() {
            listeningHistoryTable.tableHeaderView = nil
            return
        }
        if listeningHistoryTable.tableHeaderView != nil {
            return
        }
        listeningHistoryTable.tableHeaderView = informationalBannerCoordinator.tableHeaderView(size: CGSize(width: listeningHistoryTable.bounds.width, height: 150)) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.listeningHistoryTable.tableHeaderView = nil
            }
        }
    }

    private func refreshContentUnavailable() {
        var config: UIContentConfiguration?

        listeningHistoryTable.backgroundView = UIView()
        listeningHistoryTable.themeStyle = .primaryUi04

        if episodes.isEmpty {
            if searchController?.searchTextField.text?.isEmpty == false {
                // Empty State when searching
                let title = L10n.listeningHistorySearchNoEpisodesTitle
                let message = L10n.listeningHistorySearchNoEpisodesText
                config = ContentUnavailableConfiguration.emptyState(
                    title: title,
                    message: message,
                    icon: { Image("profile-download").renderingMode(.template) }
                )

                listeningHistoryTable.backgroundColor = UIColor(Theme.sharedTheme.primaryUi02)
                listeningHistoryTable.backgroundView = config?.makeContentView()
            } else {
                // Empty State when not searching
                let title = L10n.profileListeningHistoryEmptyTitle
                let message = L10n.profileListeningHistoryEmptyDescription
                config = ContentUnavailableConfiguration.emptyState(title: title, message: message, icon: { Image("options-history").renderingMode(.template) }, actions: [
                    .init(title: L10n.goToDiscover, action: {
                        Analytics.shared.track(.listeningHistoryDiscoverButtonTapped)
                        NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey)
                    })
                ])

                if #available(iOS 17.0, *) {
                    self.contentUnavailableConfiguration = config
                } else {
                    self.setContentUnavailableConfiguration(config)
                }
            }
        }
    }
}

// MARK: - Analytics

extension ListeningHistoryViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .listeningHistory
    }
}

// MARK: - Analytics

extension ListeningHistoryViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        tempEpisodes = episodes
    }

    func searchDidEnd() {
        listeningHistoryTable.isHidden = tempEpisodes.isEmpty
        episodes = tempEpisodes
        listeningHistoryTable.reloadData()
        tempEpisodes.removeAll()
    }

    func searchWasCleared() {
        Analytics.track(.searchCleared, source: analyticsSource)

        listeningHistoryTable.isHidden = tempEpisodes.isEmpty
        episodes = tempEpisodes
        listeningHistoryTable.reloadData()
    }

    func searchTermChanged(_ searchTerm: String) { }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        Analytics.track(.searchPerformed, source: analyticsSource)

        let oldData = episodes
        let newData = episodesDataManager.searchEpisodes(for: searchTerm)

        let changeSet = StagedChangeset(source: oldData, target: newData)
        self.listeningHistoryTable.reload(using: changeSet, with: .none, setData: { data in
            self.episodes = data
        })
        completion()
    }

    private func setupSearchController() {
        searchController = PCSearchBarController()
        searchController?.searchDebounce = 0.2

        guard let searchController else {
            return
        }

        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.didMove(toParent: self)

        let topAnchor = searchController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor
        ])

        searchController.placeholderText = L10n.search
        searchController.searchControllerTopConstant = topAnchor
        searchController.setupScrollView(listeningHistoryTable, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self

        listeningHistoryTable.verticalScrollIndicatorInsets.top = PCSearchBarController.defaultHeight
    }
}
