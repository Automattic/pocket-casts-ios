import UIKit
import PocketCastsDataModel
import DifferenceKit
import SwiftUI

class PlaylistDetailViewController: FakeNavViewController {
    private(set) var viewModel: PlaylistDetailViewModel!

    private(set) var searchController: PCSearchBarController! {
        didSet {
            searchController.backgroundColorOverride = AppTheme.colorForStyle(.primaryUi02)
            searchController.searchDebounce = 0.2
            searchController.placeholderText = L10n.search
            searchController.setupScrollView(tableView, hideSearchInitially: false)
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
            view.addSubview(loadingIndicator)
            loadingIndicator.center = view.center
        }
    }

    private var refreshControl: CustomRefreshControl?

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.tableView.beginUpdates()
                self.tableView.setEditing(self.isMultiSelectEnabled, animated: true)
                self.insetAdjuster.isMultiSelectEnabled = isMultiSelectEnabled
                self.tableView.endUpdates()

                if self.isMultiSelectEnabled {
                    if self.viewModel.isSearching {
                        self.searchController.searchTextField.resignFirstResponder()
                    }
                    Analytics.track(.filterMultiSelectEntered)
                    if self.selectedEpisodes.count == 0, self.longPressMultiSelectIndexPath == nil, !self.multiSelectGestureInProgress {
                        self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 1), at: .top, animated: true)
                    }
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.tableView.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                    self.multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
                    self.multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
                    self.multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
                    self.updateSelectAllBtn()
                    self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    self.multiSelectHeaderView.isHidden = false
                    self.view.bringSubviewToFront(self.multiSelectHeaderView)

                    // Adjusts multiSelectHeaderView based on screen width
                    self.setMultiSelectHeaderViewConstraint()
                } else {
                    Analytics.track(.filterMultiSelectExited)
                    self.multiSelectFooter.isHidden = true
                    self.multiSelectHeaderView.isHidden = true
                    self.selectedEpisodes.removeAll()
                }
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

    var multiSelectFooter: MultiSelectFooterView! {
        didSet {
            multiSelectFooter.translatesAutoresizingMaskIntoConstraints = false
            multiSelectFooter.isHidden = true
            multiSelectFooter.delegate = self
        }
    }

    var multiSelectFooterBottomConstraint: NSLayoutConstraint!
    var multiSelectHeaderViewConstraint: NSLayoutConstraint!

    var multiSelectAllBtn: UIButton! {
        didSet {
            multiSelectAllBtn.translatesAutoresizingMaskIntoConstraints = false
            multiSelectAllBtn.addTarget(self, action: #selector(selectAllTapped), for: .touchUpInside)
        }
    }

    var multiSelectCancelBtn: UIButton! {
        didSet {
            multiSelectCancelBtn.translatesAutoresizingMaskIntoConstraints = false
            multiSelectCancelBtn.setTitle(L10n.cancel, for: .normal)
            multiSelectCancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        }
    }

    var multiSelectHeaderView: ThemeableView! {
        didSet {
            multiSelectHeaderView.translatesAutoresizingMaskIntoConstraints = false
            multiSelectHeaderView.isHidden = true
        }
    }

    init(playlist: EpisodeFilter) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = PlaylistDetailViewModel(playlist: playlist) { [weak self] newSet, animated, contentChanged in
            self?.reload(data: newSet, animated: animated, contentChanged: contentChanged)
        } onButtonTapped: { [weak self] buttonTag in
            guard let self else { return }
            switch buttonTag {
            case .playAll:
                PlaybackManager.shared.play(filter: self.viewModel.playlist)
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
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true

        setupContent()
        setupNavigation()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        addObservers()
        updateColors()
        reloadNavTitle()

        viewModel.reloadPlaylistAndEpisodes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        updateColors()
        refreshControl?.parentViewControllerDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        refreshControl?.parentViewControllerDidDisappear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let window = view.window else { return }

        let multiSelectFooterOffset: CGFloat = isMultiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        let keyBoardHeight = viewModel.isSearching ? keyBoardHeight : 0
        tableView.contentInset = UIEdgeInsets(top: navBarHeight(window: window), left: 0, bottom: miniPlayerOffset + multiSelectFooterOffset + keyBoardHeight, right: 0)
        tableView.verticalScrollIndicatorInsets = tableView.contentInset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
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

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        refreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshControl?.scrollViewDidEndDragging(scrollView)
    }

    private func setupNavigation() {
        supportsGoogleCast = false

        reloadNavTitle()
        scrollPointToChangeTitle = PodcastHeaderView.Constants.smallImageSize

        addRightAction(image: UIImage(named: "more"), accessibilityLabel: L10n.learnMore, action: #selector(moreTapped))

        closeTapped = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
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
        searchController.searchControllerTopConstant = topAnchor

        multiSelectHeaderView = ThemeableView()
        view.addSubview(multiSelectHeaderView)

        multiSelectAllBtn = UIButton()
        multiSelectHeaderView.addSubview(multiSelectAllBtn)

        multiSelectCancelBtn = UIButton()
        multiSelectHeaderView.addSubview(multiSelectCancelBtn)

        multiSelectHeaderViewConstraint = multiSelectHeaderView.heightAnchor.constraint(equalToConstant: 90.0)

        multiSelectFooter = MultiSelectFooterView(frame: .zero)
        view.addSubview(multiSelectFooter)

        multiSelectFooterBottomConstraint = tableView.bottomAnchor.constraint(equalTo: multiSelectFooter.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            blurHeaderView.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: PodcastHeaderView.Constants.largeImageSize),
            blurHeaderView.heightAnchor.constraint(equalTo: view.widthAnchor, constant: 40),
            blurHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            blurHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),

            searchController.view.leadingAnchor.constraint(equalTo: searchHeaderView.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: searchHeaderView.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor,

            multiSelectHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            multiSelectHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            multiSelectHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            multiSelectHeaderViewConstraint,

            multiSelectAllBtn.leadingAnchor.constraint(equalTo: multiSelectHeaderView.leadingAnchor, constant: 16),
            multiSelectAllBtn.bottomAnchor.constraint(equalTo: multiSelectHeaderView.bottomAnchor),
            multiSelectAllBtn.heightAnchor.constraint(equalToConstant: 44),

            multiSelectCancelBtn.trailingAnchor.constraint(equalTo: multiSelectHeaderView.trailingAnchor, constant: -16),
            multiSelectCancelBtn.bottomAnchor.constraint(equalTo: multiSelectHeaderView.bottomAnchor),
            multiSelectCancelBtn.heightAnchor.constraint(equalToConstant: 44),

            multiSelectFooter.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            multiSelectFooter.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            multiSelectFooterBottomConstraint,
            multiSelectFooter.heightAnchor.constraint(equalToConstant: 64)
        ])

        view.layoutSubviews()
    }

    private func updateColors() {
        tableView.reloadData()

        updateNavColors(bgColor: .clear, titleColor: ThemeColor.primaryText01(), buttonColor: UIColor.white, buttonBackgroundColor: UIColor.black.withAlphaComponent(0.32))

        multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
        multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
        multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
        // we need to do this for scenarios when theme was changed
        updateNavigationBar(position: tableView.contentOffset.y)

        searchController.backgroundColorOverride = AppTheme.colorForStyle(.primaryUi02)
        searchHeaderView.backgroundColor = AppTheme.colorForStyle(.primaryUi02)
    }

    private func setupRefreshControl() {
        refreshControl = CustomRefreshControl()
        refreshControl?.customTintColor = AppTheme.colorForStyle(.secondaryText02)
        refreshControl?.perform = { [weak self] in
            self?.viewModel.reloadPlaylistAndEpisodes()
        }
        tableView.refreshControl = refreshControl
    }

    private func setMultiSelectHeaderViewConstraint() {
        let heightConstant: CGFloat = 40
        self.multiSelectHeaderViewConstraint.constant = heightConstant + view.safeAreaInsets.top
    }

    private func reload(data: StagedChangeset<PlaylistDetailViewModel.DataSourceValue>, animated: Bool, contentChanged: Bool) {
        refreshControl?.endRefreshing()

        if animated, contentChanged {
            tableView.reload(using: data, with: .none) { [weak self] newData in
                self?.viewModel.update(data: newData)
            }
        } else {
            if let data = data.last?.data, contentChanged {
                viewModel.update(data: data)
            }
            tableView.reloadData()
        }
        reloadEmptyState()
        refreshMultiSelectEpisodes()
    }

    private func reloadNavTitle() {
        navTitle = viewModel.playlist.playlistName
    }

    @objc func refreshFilterFromNotification(notification: Notification) {
        if viewModel.firstTimeLoading {
            loadingIndicator.startAnimating()
        }
        reloadNavTitle()
        viewModel.reloadPlaylistAndEpisodes()
    }

    @objc func refreshEpisodesFromNotification(notification: Notification) {
        viewModel.reloadEpisodeList()
    }

    func editPlaylist() {
        let vc = PlaylistPreviewViewController(playlist: self.viewModel.playlist) { [weak self] in
            self?.viewModel.reloadPlaylistAndEpisodes()
        }
        let navVC = SJUIUtils.navController(for: vc)
        present(navVC, animated: true, completion: nil)
    }

    func addEpisodes() {
        let searchAnalyticsHelper = SearchAnalyticsHelper(source: .unknown)
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
}

extension PlaylistDetailViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .filters
    }
}
