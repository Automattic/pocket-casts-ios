import SwiftUI
import DifferenceKit
import UIKit
import PocketCastsDataModel
import PocketCastsDependencyInjection
import PocketCastsServer
import PocketCastsUtils
import Combine

class PlaylistsViewController: PCViewController, FilterCreatedDelegate {

    @Dependency(\.playlistMetadataLoader) private var playlistMetadataLoader: PlaylistMetadataLoader
    @Dependency(\.playlistCacheInvalidationCoordinator) private var cacheInvalidationCoordinator: PlaylistCacheInvalidationCoordinator

    private var staleCancellable: AnyCancellable?
    @IBOutlet var filtersTable: ThemeableTable! {
        didSet {
            registerCells()
            if FeatureFlag.playlistsRebranding.enabled {
                filtersTable.themeStyle = .primaryUi01
                filtersTable.dragDelegate = self
                filtersTable.dropDelegate = self
                filtersTable.separatorStyle = .none
            } else {
                filtersTable.themeStyle = .primaryUi04
                filtersTable.dragDelegate = nil
                filtersTable.dropDelegate = nil
            }
            filtersTable.sectionFooterHeight = UITableView.automaticDimension
            filtersTable.estimatedSectionFooterHeight = UITableView.automaticDimension
        }
    }

    var listPlaylistItems: [ListPlaylist] = [] {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshContentUnavailable()
                }
            }
        }
    }

    var sourceIndexPath: IndexPath?
    var snapshot: UIView?
    var previouslyDisplayedDetail = false
    var presentingPlaylistDetail: Bool = false

    private let debounce = Debounce(delay: Constants.defaultDebounceTime)

    @IBOutlet var footerView: ThemeableView! {
        didSet {
            footerView.style = .primaryUi04
        }
    }

    @IBOutlet var newFilterButton: UIButton! {
        didSet {
            newFilterButton.isHidden = true
            newFilterButton.setTitle(L10n.filtersNewFilterButton, for: .normal)
        }
    }

    private var loadingIndicator: ThemeLoadingIndicator! {
        didSet {
            view.addSubview(loadingIndicator)
            loadingIndicator.center = view.center
        }
    }

    var newFilterTip: UIViewController? = nil

    private var firstTimeLoading = true

    lazy private var informationalBannerCoordinator: InformationalBannerViewCoordinator = {
        let invertedColor: Bool? = FeatureFlag.playlistsRebranding.enabled ? true : nil
        let bannerType: InformationalBannerType = FeatureFlag.playlistsRebranding.enabled ? .playlists : .filters
        let viewModel = InformationalBannerViewModel(bannerType: bannerType, invertedColor: invertedColor)
        return InformationalBannerViewCoordinator(viewModel: viewModel)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if FeatureFlag.playlistsRebranding.enabled {
            let barButton = UIBarButtonItem(image: UIImage(named: "playlist_add_icon"), style: .plain, target: self, action: #selector(addNewFilter))
            barButton.tintColor = ThemeColor.secondaryIcon01()
            customRightBtn = barButton
        } else {
            customRightBtn = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        }
        customRightBtn?.accessibilityLabel = L10n.playlistsDefaultNewPlaylist

        title = FeatureFlag.playlistsRebranding.enabled ? L10n.playlists : L10n.filters

        if FeatureFlag.playlistsRebranding.enabled {
            if !previouslyDisplayedDetail {
                autoPushPlaylist()
            }
        } else {
            autoPushPlaylist()
        }

        loadingIndicator = ThemeLoadingIndicator()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: filtersTable)
        if !FeatureFlag.playlistsRebranding.enabled {
            setupNewFilterButton()
        }
        handleThemeChanged()

        // Start cache invalidation coordinator and subscribe to stale updates
        if FeatureFlag.playlistCacheInvalidation.enabled {
            cacheInvalidationCoordinator.startObserving()
            subscribeToStaleUpdates()
        }
    }

    func autoPushPlaylist() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            if let lastFilterUuid = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastFilterShown), let filter = DataManager.sharedManager.findPlaylist(uuid: lastFilterUuid) {
                DispatchQueue.main.async {
                    self.showFilter(filter)
                }
            }
        }
    }

    func setupNewFilterButton() {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: filtersTable.bounds.width, height: 55))
        filtersTable.tableFooterView = footer
        footer.addSubview(footerView)
        footerView.anchorToAllSidesOf(view: footer)
        newFilterButton.layer.cornerRadius = 7
        newFilterButton.layer.borderWidth = 2
        newFilterButton.setLetterSpacing(-0.2)
        newFilterButton.titleLabel?.font = UIFont.font(ofSize: 15, weight: .medium, scalingWith: .subheadline)
        newFilterButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Invalidate stale playlist metadata cache (>30s) to ensure fresh data on screen entry.
        // This is lightweight and won't block - just clears dictionaries if threshold exceeded.
        if !FeatureFlag.playlistCacheInvalidation.enabled {
            Task {
                await playlistMetadataLoader.invalidateCacheIfStale()
            }
        }

        reloadFilters()
        setupInformationalBanner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavTintColors()
        addCustomObserver(Constants.Notifications.playlistChanged, selector: #selector(filtersUpdated))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        Analytics.track(.filterListShown, properties: ["filter_count": listPlaylistItems.count])

        showPlaylistsTipIfNeeded()
        showOnboardingScreenIfNeeded()

        UserDefaults.standard.set(nil, forKey: Constants.UserDefaults.lastFilterShown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        navigationController?.navigationBar.shadowImage = nil
    }

    @objc private func editTapped() {
        filtersTable.isEditing = !filtersTable.isEditing
        filtersTable.reloadData() // this is needed to ensure the cell re-arrange controls are tinted correctly
        customRightBtn = UIBarButtonItem(barButtonSystemItem: filtersTable.isEditing ? .done : .edit, target: self, action: #selector(editTapped))
        refreshRightButtons()

        Analytics.track(.filterListEditButtonToggled, properties: ["editing": filtersTable.isEditing])
    }

    @objc private func checkForScrollTap(_ notification: Notification) {
        let topOffset = view.safeAreaInsets.top
        if let index = notification.object as? Int, index == tabBarItem.tag, filtersTable.contentOffset.y > -topOffset {
            filtersTable.setContentOffset(CGPoint(x: 0, y: -topOffset), animated: true)
        }
    }

    @objc private func filtersUpdated() {
        if FeatureFlag.playlistsRebranding.enabled, !firstTimeLoading {
            debounce.call { [weak self] in
                self?.reloadFilters()
            }
        } else {
            reloadFilters()
        }
    }

    @IBAction func addNewFilter() {
        Analytics.track(.filterCreateButtonTapped)
        presentFilterPreview()
    }

    private func presentFilterPreview() {
        if FeatureFlag.playlistsRebranding.enabled {
            let createPlaylistVC = NewPlaylistViewController()
            createPlaylistVC.delegate = self
            let navVC = SJUIUtils.navController(for: createPlaylistVC)
            present(navVC, animated: true, completion: nil)
        } else {
            let createFilterVC = FilterPreviewViewController()
            createFilterVC.delegate = self
            let navVC = SJUIUtils.navController(for: createFilterVC)
            present(navVC, animated: true, completion: nil)
        }
    }

    override func handleThemeChanged() {
        filtersTable.reloadData()
        updateNavTintColors()
        newFilterButton.layer.borderColor = ThemeColor.primaryInteractive01().cgColor
        newFilterButton.titleLabel?.textColor = ThemeColor.primaryInteractive01()
        if FeatureFlag.playlistsRebranding.enabled {
            view.backgroundColor = ThemeColor.primaryUi04()
            customRightBtn?.tintColor = ThemeColor.secondaryIcon01()
        }
    }

    private func updateNavTintColors() {
        changeNavTint(titleColor: AppTheme.navBarTitleColor(), iconsColor: AppTheme.navBarIconsColor())
    }

    func showFilter(_ filter: EpisodeFilter, isNew: Bool? = false) {
        previouslyDisplayedDetail = true
        presentingPlaylistDetail = true

        let viewController: UIViewController
        if FeatureFlag.playlistsRebranding.enabled {
            viewController = PlaylistDetailViewController(playlist: filter, delegate: self)
        } else {
            let playlistViewController = PlaylistViewController(filter: filter)
            playlistViewController.isNewFilter = isNew ?? false
            viewController = playlistViewController
        }
        navigationController?.popToRootViewController(animated: false)
        navigationController?.pushViewController(viewController, animated: true)

        UserDefaults.standard.set(filter.uuid, forKey: Constants.UserDefaults.lastFilterShown)
    }

    private func reloadFilters() {
        if firstTimeLoading {
            loadingIndicator.startAnimating()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let newData = DataManager.sharedManager.allPlaylists(includeDeleted: false).map { ListPlaylist(playlist: $0) }

            if FeatureFlag.playlistsRebranding.enabled {
                let oldData = self.listPlaylistItems

                let changeSet = StagedChangeset(source: oldData, target: newData)

                if oldData.isContentEqual(to: newData) {
                    DispatchQueue.main.async {
                        self.newFilterButton.isHidden = false
                        self.loadingIndicator.stopAnimating()
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.newFilterButton.isHidden = false
                    self.loadingIndicator.stopAnimating()
                    do {
                        try SJCommonUtils.catchException { [weak self] in
                            self?.filtersTable.reload(using: changeSet, with: .fade) { [weak self] newData in
                                self?.listPlaylistItems = newData
                            }
                        }
                    } catch {
                        if let data = changeSet.last?.data {
                            self.listPlaylistItems = data
                        }
                        self.filtersTable.reloadData()
                    }
                }
                return
            }

            firstTimeLoading = false
            DispatchQueue.main.async {
                self.newFilterButton.isHidden = false
                self.loadingIndicator.stopAnimating()
                self.filtersTable.reloadData()
            }
        }
    }

    private func setupInformationalBanner() {
        if !informationalBannerCoordinator.shouldShowBanner() {
            filtersTable.tableHeaderView = nil
            return
        }
        if filtersTable.tableHeaderView != nil {
            return
        }
        filtersTable.tableHeaderView = informationalBannerCoordinator.tableHeaderView(size: CGSize(width: filtersTable.bounds.width, height: 135)) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.filtersTable.tableHeaderView = nil
            }
        }
    }

    private func showOnboardingScreenIfNeeded() {
        guard FeatureFlag.playlistsRebranding.enabled else { return }

        let userIsLoggedIn = SyncManager.isUserLoggedIn()
        let appInstallStateUpdated = (UIApplication.shared.delegate as? AppDelegate)?.appInstallState == .updated
        let shouldDisplayOnboarding = appInstallStateUpdated && Settings.shouldShowPlaylistsOnboarding && userIsLoggedIn
        guard shouldDisplayOnboarding else { return }
        let vc = ThemedHostingController(
            rootView: PlaylistsOnboardingView(
                onClose: { [weak self] in
                    self?.dismiss(animated: true)
                }
            )
        )
        present(vc, animated: true)
    }

    private func refreshContentUnavailable() {
        guard FeatureFlag.playlistsRebranding.enabled else {
            set(configuration: nil)
            return
        }

        customRightBtn?.isHidden = listPlaylistItems.isEmpty

        var config: UIContentConfiguration?

        if listPlaylistItems.isEmpty {
            // Empty State when playlists is empty
            let title = L10n.playlistsEmptyStateTitle
            let message = L10n.playlistsEmptyStateDescription
            config = ContentUnavailableConfiguration.emptyState(
                title: title,
                message: message,
                icon: {
                    Image("filter_list")
                },
                actions: [
                .init(
                    title: L10n.playlistsDefaultNewPlaylist,
                    action: { [weak self] in
                    self?.addNewFilter()
                    }
                )
            ])
        }
        set(configuration: config)
    }

    private func set(configuration: UIContentConfiguration?) {
        if #available(iOS 17.0, *) {
            self.contentUnavailableConfiguration = configuration
        } else {
            self.setContentUnavailableConfiguration(configuration)
        }
    }

    // MARK: - Stale Cache Handling

    private func subscribeToStaleUpdates() {
        staleCancellable = playlistMetadataLoader.stalePlaylistsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stalePlaylistIDs in
                self?.refreshStaleCells(playlistIDs: stalePlaylistIDs)
            }
    }

    /// Refreshes visible cells for playlists that have become stale.
    /// Only triggers reload for cells that are currently visible.
    private func refreshStaleCells(playlistIDs: Set<String>) {
        guard !playlistIDs.isEmpty else { return }

        // Get visible cells and their index paths
        guard let visibleIndexPaths = filtersTable.indexPathsForVisibleRows else { return }

        var indexPathsToRefresh: [IndexPath] = []

        for indexPath in visibleIndexPaths {
            guard indexPath.row < listPlaylistItems.count else { continue }
            let playlist = listPlaylistItems[indexPath.row]
            if playlistIDs.contains(playlist.playlist.uuid) {
                indexPathsToRefresh.append(indexPath)
            }
        }

        // Reload only the affected visible cells
        if !indexPathsToRefresh.isEmpty {
            filtersTable.reloadRows(at: indexPathsToRefresh, with: .none)
        }
    }

    // MARK: - FilterCreationDelegate

    func filterCreated(newFilter: EpisodeFilter) {
        showFilter(newFilter, isNew: true)
    }
}
