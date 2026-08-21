import DifferenceKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class ListeningHistoryViewController: PCViewController {
    var episodes = [ArraySection<String, ListEpisode>]()

    /// The term the list is filtered by, `nil` when not searching. Loads that happen while a search
    /// is active re-run the search instead of replacing the results with the full history.
    private var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }

            hasLoadedSearchTerm = false
        }
    }

    /// Whether a load for the current `searchTerm` has finished. Until it has there's no answer to
    /// show yet, so the list shows a loading indicator rather than an empty state.
    private var hasLoadedSearchTerm = false

    private var contentState = ListeningHistoryContentState.content {
        didSet {
            guard contentState != oldValue else { return }

            applyContentState()
        }
    }

    private let operationQueue = OperationQueue()
    var cellHeights: [IndexPath: CGFloat] = [:]

    private let episodesDataManager = EpisodesDataManager()
    private var searchController: PCSearchBarController?

    private lazy var informationalBannerCoordinator: InformationalBannerViewCoordinator = {
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

    @MainActor
    var isMultiSelectEnabled = false {
        didSet {
            setupNavBar()
            setEnclosingTabBarHidden(isMultiSelectEnabled, animated: false)
            listeningHistoryTable.beginUpdates()
            listeningHistoryTable.setEditing(isMultiSelectEnabled, animated: true)
            listeningHistoryTable.endUpdates()
            insetAdjuster.isMultiSelectEnabled = isMultiSelectEnabled
            if isMultiSelectEnabled {
                Analytics.track(.listeningHistoryMultiSelectEntered)
                multiSelectFooter.setSelectedCount(count: selectedEpisodes.count)
                multiSelectFooterBottomConstraint.constant = Constants.effectiveFooterViewPadding
                if let selectedIndexPath = longPressMultiSelectIndexPath {
                    listeningHistoryTable.selectIndexPath(selectedIndexPath)
                    longPressMultiSelectIndexPath = nil
                }
            } else {
                Analytics.track(.listeningHistoryMultiSelectExited)
                selectedEpisodes.removeAll()
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

        setupSearchController()

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

        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.listeningHistoryChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(ServerNotifications.syncCompleted, selector: #selector(refreshEpisodesFromBackgroundNotification))
    }

    @objc private func refreshEpisodesFromNotification() {
        refreshEpisodes(animated: true)
    }

    @objc private func refreshEpisodesFromBackgroundNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshEpisodes(animated: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func handleThemeChanged() {
        listeningHistoryTable.reloadData()
    }

    func refreshEpisodes(animated: Bool, completion: (() -> Void)? = nil) {
        let searchTerm = searchTerm
        refreshContentUnavailable()

        operationQueue.addOperation { [weak self] in
            guard let self else { return }

            let newData = searchTerm.map { self.episodesDataManager.searchEpisodes(for: $0) } ?? self.episodesDataManager.listeningHistoryEpisodes()

            DispatchQueue.main.sync {
                defer { completion?() }

                guard searchTerm == self.searchTerm else { return }

                self.setEpisodes(newData, animated: animated)
                self.hasLoadedSearchTerm = true
                self.refreshContentUnavailable()
            }
        }
    }

    private func setEpisodes(_ newData: [ArraySection<String, ListEpisode>], animated: Bool) {
        if animated {
            let changeSet = StagedChangeset(source: episodes, target: newData)
            listeningHistoryTable.reload(using: changeSet, with: .none, setData: { data in
                self.episodes = data
            })
        } else {
            episodes = newData
            listeningHistoryTable.reloadData()
        }
    }

    @objc func clearTapped() {
        let alert = UIAlertController(
            title: L10n.historyClearAllDetails,
            message: L10n.historyClearAllDetailsMsg,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            Analytics.track(.listeningHistoryClearConfirmationDismissed)
        })
        alert.addAction(UIAlertAction(title: L10n.historyClearAll, style: .destructive) { [weak self] _ in
            Analytics.track(.listeningHistoryCleared)
            DataManager.sharedManager.clearAllEpisodePlayInteractions()
            if SyncManager.isUserLoggedIn() { ServerSettings.setLastClearHistoryDate(Date()) }
            self?.refreshEpisodes(animated: true)
        })
        present(alert, animated: true)
        Analytics.track(.listeningHistoryClearConfirmationShown)
    }

    func setupNavBar() {
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(menuTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilityMoreActions

        navigationItem.setLeftBarButton(isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectAllTapped)) : nil, animated: true)
        navigationItem.setHidesBackButton(isMultiSelectEnabled, animated: true)
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

        optionsPicker.present(from: self)
    }

    private func setupInformationalBanner() {
        if !informationalBannerCoordinator.shouldShowBanner() {
            listeningHistoryTable.tableHeaderView = nil
            return
        }
        if listeningHistoryTable.tableHeaderView != nil {
            return
        }
        listeningHistoryTable.tableHeaderView = informationalBannerCoordinator.tableHeaderView(size: CGSize(width: listeningHistoryTable.bounds.width, height: 138)) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.listeningHistoryTable.tableHeaderView = nil
            }
        }
    }

    private func refreshContentUnavailable() {
        contentState = ListeningHistoryContentState(
            isEmpty: episodes.isEmpty,
            hasLoaded: hasLoadedSearchTerm,
            isSearching: searchTerm != nil
        )
    }

    private func applyContentState() {
        listeningHistoryTable.backgroundView = UIView()
        listeningHistoryTable.themeStyle = LiquidGlass.isEnabled ? .primaryUi02 : .primaryUi04
        listeningHistoryTable.isHidden = false
        contentUnavailableConfiguration = nil

        switch contentState {
        case .content:
            break
        case .loading:
            listeningHistoryTable.backgroundView = ContentUnavailableConfiguration.loading().makeContentView()
        case .noSearchResults:
            let config = ContentUnavailableConfiguration.emptyState(
                title: L10n.listeningHistorySearchNoEpisodesTitle,
                message: L10n.listeningHistorySearchNoEpisodesText,
                icon: { Image("profile-download").renderingMode(.template) }
            )

            listeningHistoryTable.themeStyle = .primaryUi02
            listeningHistoryTable.backgroundView = config.makeContentView()
        case .noHistory:
            listeningHistoryTable.isHidden = true
            contentUnavailableConfiguration = ContentUnavailableConfiguration.emptyState(
                title: L10n.profileListeningHistoryEmptyTitle,
                message: L10n.profileListeningHistoryEmptyDescription,
                icon: { Image("options-history").renderingMode(.template) },
                actions: [
                    .init(title: L10n.goToDiscover, action: {
                        Analytics.track(.listeningHistoryDiscoverButtonTapped)
                        NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey)
                    })
                ]
            )
        }
    }
}

// MARK: - Content state

/// What the list shows in place of its rows. Derived from what has actually been loaded rather than
/// from the row count alone, so a load that's still running never reads as "no episodes".
enum ListeningHistoryContentState: Equatable {
    /// The rows themselves.
    case content

    /// The load for the current search term hasn't produced an answer yet.
    case loading

    /// The search finished without matching anything.
    case noSearchResults

    /// There's nothing in the listening history.
    case noHistory

    init(isEmpty: Bool, hasLoaded: Bool, isSearching: Bool) {
        switch (isEmpty, hasLoaded, isSearching) {
        case (false, _, _):
            self = .content
        case (true, false, _):
            self = .loading
        case (true, true, true):
            self = .noSearchResults
        case (true, true, false):
            self = .noHistory
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
    func searchDidBegin() { }

    func searchDidEnd() {
        endSearch()
    }

    func searchWasCleared() {
        Analytics.track(.searchCleared, source: analyticsSource)

        endSearch()
    }

    func searchTermChanged(_ searchTerm: String) { }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        Analytics.track(.searchPerformed, source: analyticsSource)

        self.searchTerm = searchTerm
        refreshEpisodes(animated: false, completion: completion)
    }

    private func endSearch() {
        guard searchTerm != nil else { return }

        searchTerm = nil
        refreshEpisodes(animated: false)
    }

    private func setupSearchController() {
        searchController = PCSearchBarController()

        guard let searchController else {
            return
        }

        searchController.install(in: self, attachedTo: listeningHistoryTable)
        // Plain-style table view pins section headers below `adjustedContentInset.top`, so keep
        // the inset matched to the bar height — otherwise headers would pin where the (collapsed)
        // bar used to be, leaving a gap under the nav bar.
        searchController.tracksContentInsetToBarHeight = true

        searchController.placeholderText = L10n.search
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self
    }
}

// MARK: - UIScrollViewDelegate

extension ListeningHistoryViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchController?.parentScrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        searchController?.parentScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        searchController?.parentScrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        searchController?.parentScrollViewDidEndScrollingAnimation(scrollView)
    }
}
