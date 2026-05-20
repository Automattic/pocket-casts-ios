import UIKit
import PocketCastsDataModel
import DifferenceKit
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class PlaylistDetailViewController: PCViewController, UIScrollViewDelegate {
    private(set) var viewModel: PlaylistDetailViewModel!

    private(set) var searchController: PCSearchBarController! {
        didSet {
            searchController.backgroundColorOverride = AppTheme.colorForStyle(.primaryUi02)
            searchController.searchDebounce = 0.2
            searchController.placeholderText = L10n.search
            searchController.searchDebounce = Settings.podcastSearchDebounceTime()
            searchController.searchDelegate = self
            searchController.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(searchController)
        }
    }

    lazy private(set) var searchHeaderView: UIView = {
        let header = UIView(frame: .zero)
        header.backgroundColor = AppTheme.colorForStyle(.primaryUi02)
        return header
    }()

    private(set) var tableView: ThemeableTable! {
        didSet {
            tableView.themeStyle = .primaryUi02
            tableView.estimatedRowHeight = 80
            tableView.rowHeight = UITableView.automaticDimension
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.sectionHeaderTopPadding = 0
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.isHidden = true
            tableView.allowsMultipleSelection = true
            tableView.allowsMultipleSelectionDuringEditing = true
            registerCells()
            registerLongPress()
        }
    }

    private lazy var blurHeaderView: UIView = {
        let headerView = PlaylistBlurHeaderView(viewModel: self.viewModel).themedUIView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear
        headerView.layer.zPosition = -1000
        headerView.isUserInteractionEnabled = false
        return headerView
    }()

    private var loadingIndicator: ThemeLoadingIndicator! {
        didSet {
            loadingIndicator.hidesWhenStopped = true
            view.addSubview(loadingIndicator)
            loadingIndicator.center = view.center
        }
    }

    private var refreshControl: CustomRefreshControl?

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.tableView.beginUpdates()
                self.tableView.setEditing(self.isMultiSelectEnabled, animated: true)
                self.insetAdjuster.isMultiSelectEnabled = isMultiSelectEnabled
                self.tableView.endUpdates()

                if self.isMultiSelectEnabled {
                    if self.viewModel.isSearching {
                        self.searchController.searchTextField.resignFirstResponder()
                    }
                    self.track(.filterMultiSelectEntered)
                    if self.selectedEpisodes.isEmpty, self.longPressMultiSelectIndexPath == nil, !self.multiSelectGestureInProgress {
                        self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 1), at: .top, animated: true)
                    }
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.tableView.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                    self.multiSelectFooterBottomConstraint.constant = Constants.effectiveFooterViewPadding
                } else {
                    self.track(.filterMultiSelectExited)
                    self.multiSelectFooter.isHidden = true
                    self.selectedEpisodes.removeAll()
                }
                self.updateMultiSelectNavBar()
            }
        }
    }

    var selectedEpisodes = [ListEpisode]() {
        didSet {
            multiSelectFooter.setSelectedCount(count: selectedEpisodes.count)
            updateSelectAllBtn()
        }
    }

    var keyBoardHeight: CGFloat = .zero
    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
    var multiSelectActionInProgress = false
    var preSearchContentOffset: CGPoint?

    var multiSelectFooter: MultiSelectFooterView! {
        didSet {
            multiSelectFooter.translatesAutoresizingMaskIntoConstraints = false
            multiSelectFooter.isHidden = true
            multiSelectFooter.delegate = self
        }
    }

    var multiSelectFooterBottomConstraint: NSLayoutConstraint!

    private var defaultRightBarButton: UIBarButtonItem?
    private var defaultBackBarButton: UIBarButtonItem?
    var multiSelectAllBarButton: UIBarButtonItem?
    var multiSelectCancelBarButton: UIBarButtonItem?

    private lazy var navTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()

    private weak var delegate: FilterCreatedDelegate?

    lazy var reloader = ReloadScheduler<PlaylistReloadScope> { [weak self] in
        self?.reload(with: $0)
    }

    init(playlist: EpisodeFilter, delegate: FilterCreatedDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.viewModel = PlaylistDetailViewModel(playlist: playlist) { [weak self] newSet, animated, contentChanged in
            self?.reload(data: newSet, animated: animated, contentChanged: contentChanged)
        } onButtonTapped: { [weak self] buttonTag in
            guard let self else { return }
            switch buttonTag {
            case .playAll:
                self.playAll()
            case .smartRules:
                self.editPlaylist()
            case .addEpisodes:
                self.addEpisodes()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        useTransparentNavigationBarAppearance = true

        super.viewDidLoad()

        setupContent()
        setupNavigation()
        setupRefreshControl()

        if viewModel.firstTimeLoading {
            loadingIndicator.startAnimating()
        }

        track(.filterShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
        updateColors()
        reloadNavTitle()

        viewModel.reloadPlaylistAndEpisodes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateColors()
        delegate?.presentingPlaylistDetail = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        if let refreshControl, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let multiSelectFooterOffset: CGFloat = isMultiSelectEnabled ? 80 : 0
        let keyBoardHeight = viewModel.isSearching ? keyBoardHeight : 0
        tableView.contentInset.bottom = Constants.effectiveMiniPlayerOffset + multiSelectFooterOffset + keyBoardHeight
        tableView.verticalScrollIndicatorInsets.bottom = tableView.contentInset.bottom
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
        tableView
    }

    override func handleThemeChanged() {
        updateColors()
    }

    override func handleAppDidEnterBackground() {
        // we don't need to keep our UI up to date while backgrounded, so remove all the notification observers we have
        removeAllCustomObservers()
    }

    override func handleAppWillBecomeActive() {
        viewModel.reloadEpisodeList()
        addObservers()
    }

    private func setupNavigation() {
        navigationItem.titleView = {
            // The label has to go inside a container view otherwise navigationBar changes its alpha
            let view = UIView()
            view.addSubview(navTitleLabel)
            navTitleLabel.anchorToAllSidesOf(view: view)
            return view
        }()
        defaultRightBarButton = FakeNavBarButton.makeBarButtonItem(
            image: UIImage(named: "more"),
            accessibilityLabel: L10n.accessibilityMoreActions,
            target: self,
            action: #selector(moreTapped)
        )
        customRightBtn = defaultRightBarButton

        if !LiquidGlass.isEnabled {
            defaultBackBarButton = FakeNavBarButton.makeBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                accessibilityLabel: L10n.back,
                target: self,
                action: #selector(backButtonTapped)
            )
            navigationItem.leftBarButtonItem = defaultBackBarButton
            navigationItem.setHidesBackButton(true, animated: false)

            if let navController = navigationController as? PCNavigationController {
                navController.enableInteractivePopGestureWorkaround()
            } else {
                assertionFailure("Expected PCNavigationController")
            }
        }
    }

    private func setupContent() {
        view.backgroundColor = AppTheme.viewBackgroundColor()

        tableView = ThemeableTable(frame: .zero, style: .grouped)
        view.insertSubview(tableView, at: 0)

        tableView.addSubview(blurHeaderView)

        loadingIndicator = ThemeLoadingIndicator()

        searchController = PCSearchBarController()
        searchHeaderView.addSubview(searchController.view)
        searchController.didMove(toParent: self)

        let topAnchor = searchController.view.topAnchor.constraint(equalTo: searchHeaderView.topAnchor)

        multiSelectFooter = MultiSelectFooterView(frame: .zero)
        view.addSubview(multiSelectFooter)

        multiSelectFooterBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blurHeaderView.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: PodcastHeaderView.Constants.largeImageSize),
            blurHeaderView.heightAnchor.constraint(equalTo: view.widthAnchor, constant: 40),
            blurHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            blurHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),

            searchController.view.leadingAnchor.constraint(equalTo: searchHeaderView.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: searchHeaderView.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor,

            multiSelectFooter.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8.0),
            multiSelectFooter.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8.0),
            multiSelectFooterBottomConstraint,
            multiSelectFooter.heightAnchor.constraint(equalToConstant: 64),
        ])

        view.layoutSubviews()
    }

    private func updateColors() {
        tableView.reloadData()
        navTitleLabel.textColor = ThemeColor.primaryText01()
        searchController.backgroundColorOverride = AppTheme.colorForStyle(.primaryUi02)
        searchHeaderView.backgroundColor = AppTheme.colorForStyle(.primaryUi02)
    }

    private func setupRefreshControl() {
        if viewModel.isManualPlaylist { return }

        refreshControl = CustomRefreshControl()
        refreshControl?.perform = { [weak self] refreshControl in
            refreshControl.set(text: L10n.refreshControlFetchingEpisodes.uppercased())
            self?.reloader.pause()
            RefreshManager.shared.refreshPodcasts { [weak self] _ in
                DispatchQueue.main.async {
                    self?.didFinishRefresh()
                }
            }
        }
        tableView.refreshControl = refreshControl
    }

    private func reload(data: StagedChangeset<PlaylistDetailViewModel.DataSourceValue>, animated: Bool, contentChanged: Bool) {
        loadingIndicator.stopAnimating()

        if animated, contentChanged {
            do {
                try SJCommonUtils.catchException {
                    tableView.reload(using: data, with: .fade) { newData in
                        viewModel.update(data: newData) { [weak self] in
                            self?.reloadRefreshControlColor()
                        }
                    }
                }
            } catch {
                if let data = data.last?.data {
                    viewModel.update(data: data) { [weak self] in
                        self?.reloadRefreshControlColor()
                    }
                }
                tableView.reloadData()
            }
        } else {
            if let data = data.last?.data {
                viewModel.update(data: data) { [weak self] in
                    self?.reloadRefreshControlColor()
                }
            }
            tableView.reloadData()
        }
        blurHeaderView.isHidden = viewModel.episodes.isEmpty
        reloadEmptyState()
        refreshMultiSelectEpisodes()

        if !viewModel.isSearching, let offset = preSearchContentOffset {
            preSearchContentOffset = nil
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.tableView.layoutIfNeeded()
                let minOffset = -self.tableView.adjustedContentInset.top
                let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
                let clampedY = min(max(offset.y, minOffset), maxOffset)
                let clamped = CGPoint(x: offset.x, y: clampedY)
                self.tableView.setContentOffset(clamped, animated: true)
            }
        }
    }

    private func didFinishRefresh() {
        refreshControl?.set(text: L10n.refreshControlRefreshComplete.uppercased())
        refreshControl?.endRefreshing()
        reloader.resume(after: .milliseconds(600))
    }

    private func reloadRefreshControlColor() {
        if let snapshot = blurHeaderView.sj_snapshotImage() {
            refreshControl?.customTintColor = snapshot.isDark ? .white : .black
        } else {
            refreshControl?.customTintColor = nil
        }
    }

    func reloadNavTitle() {
        navTitleLabel.text = viewModel.playlist.playlistName
    }

    @objc func refreshFilterFromNotification(notification: Notification) {
        reloader.request(.playlist)
    }

    @objc func refreshEpisodesFromNotification(notification: Notification) {
        reloader.request(.episodes)
    }

    private func reload(with scopes: PlaylistReloadScope) {
        if scopes.contains(.playlist) {
            reloadNavTitle()
            viewModel.reloadPlaylistAndEpisodes() // It also reloads the episode list
        } else if scopes.contains(.episodes) {
            viewModel.reloadEpisodeList()
        }
    }

    func editPlaylist() {
        track(.filterEditRulesTapped)

        let vc = PlaylistPreviewViewController(playlist: self.viewModel.playlist) { [weak self] in
            self?.viewModel.reloadPlaylistAndEpisodes()
        }
        let navVC = SJUIUtils.navController(for: vc)
        present(navVC, animated: true, completion: nil)
    }

    func addEpisodes() {
        let isPlaylistFull = viewModel.isPlaylistFull

        track(.filterAddEpisodesTapped, properties: ["is_playlist_full": isPlaylistFull])

        if isPlaylistFull {
            let theme: any ToastTheme = ToastIconTheme(iconName: "option-alert", iconColor: Theme.sharedTheme.primaryIcon01)
            Toast.show(L10n.playlistManualAddEpisodeFullPlaylistToast, theme: theme)
            return
        }

        let searchAnalyticsHelper = SearchAnalyticsHelper(source: .playlistEditor)
        let searchResults = SearchResultsModel(analyticsHelper: searchAnalyticsHelper)
        let vc = PCHostingController(rootView: LocalSearchView(
            playlist: viewModel.playlist,
            dismissAction: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.viewModel.reloadPlaylistAndEpisodes()
                }
            }
        )
            .environmentObject(Theme.sharedTheme)
            .environmentObject(searchAnalyticsHelper)
            .environmentObject(searchResults)
        )

        // Disable drag-to-dismiss gesture to ensure viewModel reload is called
        vc.isModalInPresentation = true

        let navVC = SJUIUtils.navController(for: vc)
        present(navVC, animated: true, completion: nil)
    }

    // MARK: - Scroll handling

    private var isScrolledPastHeader = false
    private var isNavBarBlurred = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let scrolled = offset > 220
        if scrolled != isScrolledPastHeader {
            isScrolledPastHeader = scrolled
            updateNavTitleVisibility(animated: true)
            updateNavBarBlur()
        }
    }

    /// Forces the standard (blurred) navigation bar appearance whenever multi-select is on or the
    /// user has scrolled past the header. Multi-select uses plain text bar buttons that can't sit
    /// on the transparent over-artwork chrome (pre-iOS 26), so we lock the bar to its blurred state
    /// while it's active. On iOS 26 `setTransparentNavBarScrolled` is a no-op for the bar visuals,
    /// so this is effectively a pre-26 fix.
    private func updateNavBarBlur() {
        let shouldBlur = isMultiSelectEnabled || isScrolledPastHeader
        guard shouldBlur != isNavBarBlurred else { return }
        isNavBarBlurred = shouldBlur
        setTransparentNavBarScrolled(shouldBlur)
    }

    /// Empty state has no scrolling, so force the title to show regardless of scroll position.
    func updateNavTitleVisibility(animated: Bool) {
        let shouldShow = isScrolledPastHeader || viewModel.shouldShowEmptyPlaceholder
        let targetAlpha: CGFloat = shouldShow ? 1 : 0
        if animated {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
                self.navTitleLabel.alpha = targetAlpha
            }
        } else {
            navTitleLabel.alpha = targetAlpha
        }
    }

    // MARK: - Multi-select nav bar

    func updateMultiSelectNavBar() {
        if isMultiSelectEnabled {
            let cancel = UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped))
            cancel.accessibilityLabel = L10n.accessibilityCancelMultiselect
            multiSelectCancelBarButton = cancel
            customRightBtn = cancel

            let selectAll = UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectAllTapped))
            multiSelectAllBarButton = selectAll
            navigationItem.setLeftBarButton(selectAll, animated: true)
            if LiquidGlass.isEnabled {
                navigationItem.setHidesBackButton(true, animated: true)
            }
            updateSelectAllBtn()
        } else {
            multiSelectCancelBarButton = nil
            multiSelectAllBarButton = nil
            customRightBtn = defaultRightBarButton
            if LiquidGlass.isEnabled {
                navigationItem.setLeftBarButton(nil, animated: true)
                navigationItem.setHidesBackButton(false, animated: true)
            } else {
                navigationItem.setLeftBarButton(defaultBackBarButton, animated: false)
            }
            refreshRightButtons()
        }
        updateNavBarBlur()
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
