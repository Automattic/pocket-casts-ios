import UIKit
import PocketCastsDataModel
import DifferenceKit
import SwiftUI

class PlaylistDetailViewController: FakeNavViewController {
    private(set) var viewModel: PlaylistDetailViewModel!
    private var searchController: PCSearchBarController! {
        didSet {
            searchController.backgroundColorOverride = AppTheme.colorForStyle(.primaryUi02)
            searchController.searchDebounce = 0.2
            searchController.placeholderText = L10n.search
            searchController.setupScrollView(tableView, hideSearchInitially: false)
            searchController.searchDebounce = Settings.podcastSearchDebounceTime()
//            searchController.searchDelegate = self
            searchController.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(searchController)
        }
    }
    lazy private var searchHeaderView: UIView = {
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
        self.viewModel = PlaylistDetailViewModel(playlist: playlist) { [weak self] newSet, animated in
            self?.reload(data: newSet, animated: animated)
        } onButtonTapped: { [weak self] buttonTag in
            guard let self else { return }
            switch buttonTag {
            case .playAll:
                PlaybackManager.shared.play(filter: self.viewModel.playlist)
            case .smartRules:
                self.editPlaylist()
            case .addEpisodes:
                break
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
        tableView.contentInset = UIEdgeInsets(top: navBarHeight(window: window), left: 0, bottom: miniPlayerOffset + multiSelectFooterOffset, right: 0)
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

        navTitle = viewModel.playlist.playlistName
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
    }

    private func setupRefreshControl() {
        refreshControl = CustomRefreshControl()
        refreshControl?.customTintColor = AppTheme.colorForStyle(.secondaryText02)
        refreshControl?.perform = { [weak self] in
            self?.refreshFilterFromNotification()
        }
        tableView.refreshControl = refreshControl
    }

    private func setMultiSelectHeaderViewConstraint() {
        let heightConstant: CGFloat = 40
        self.multiSelectHeaderViewConstraint.constant = heightConstant + view.safeAreaInsets.top
    }

    private func reload(data: StagedChangeset<[ListEpisode]>, animated: Bool = true) {
        refreshControl?.endRefreshing()

        if data.isEmpty {
            reloadEmptyState()
            return
        }

        if animated {
            tableView.reload(using: data, with: .none, setData: { [weak self] episodes in
                self?.viewModel.update(episodes: episodes)
            })
        } else {
            viewModel.update(episodes: data.last?.data ?? [])
            tableView.reloadData()
        }
        reloadEmptyState()
        refreshMultiSelectEpisodes()
    }

    @objc func refreshFilterFromNotification() {
        if viewModel.firstTimeLoading {
            loadingIndicator.startAnimating()
        }
        viewModel.reloadPlaylistAndEpisodes()
    }

    @objc func refreshEpisodesFromNotification() {
        viewModel.reloadEpisodeList()
    }

    func editPlaylist() {
        let vc = PlaylistPreviewViewController(playlist: self.viewModel.playlist) { [weak self] in
            self?.refreshFilterFromNotification()
        }
        let navVC = SJUIUtils.navController(for: vc)
        present(navVC, animated: true, completion: nil)
    }
}

extension PlaylistDetailViewController: UITableViewDataSource {
    private static let cellIdentifier = "EpisodeCell"

    func registerCells() {
        tableView.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: Self.cellIdentifier)
        tableView.register(EmptyStateCell.self, forCellReuseIdentifier: EmptyStateCell.reuseIdentifier)
        tableView.register(PlaylistHeaderViewCell.self, forCellReuseIdentifier: PlaylistHeaderViewCell.reuseIdentifier)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            guard let indexPath = tableView.indexPathForRow(at: touchPoint), indexPath.section == 1 else { return }
            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    Analytics.track(.filterSelectAllAbove)
                    self.tableView.selectAllAbove(indexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    Analytics.track(.filterSelectAllBelow)
                    self.tableView.selectAllBelow(indexPath: indexPath)
                })
                optionPicker.addAction(action: allAboveAction)
                optionPicker.addAction(action: allBelowAction)
                optionPicker.show(statusBarStyle: preferredStatusBarStyle)
            } else {
                longPressMultiSelectIndexPath = indexPath
                isMultiSelectEnabled = true
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.episodes.isEmpty, !viewModel.isSearching {
            return 0
        }
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.episodes.isEmpty, !viewModel.isSearching {
            return 0
        }
        if section == 0 {
            return 1
        }
        return viewModel.episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistHeaderViewCell.reuseIdentifier, for: indexPath) as! PlaylistHeaderViewCell
            cell.configure(viewModel: viewModel)
            return cell
        }

        if viewModel.isSearching, viewModel.episodes.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
            cell.configure(
                title: L10n.discoverNoEpisodesFound,
                message: L10n.discoverNoPodcastsFoundMsg) {
                    Image("empty-playlist-info")
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as! EpisodeCell

        cell.playlist = .filter(uuid: viewModel.playlist.uuid)
        cell.delegate = self
        if let listEpisode = viewModel.episodes[safe: indexPath.row] {
            cell.populateFrom(episode: listEpisode.episode, tintColor: viewModel.playlist.playlistColor(), filterUuid: viewModel.playlist.uuid)
            cell.shouldShowSelect = isMultiSelectEnabled
            if isMultiSelectEnabled {
                cell.showTick = selectedEpisodesContains(uuid: listEpisode.episode.uuid)
            }
        }
        return cell
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.episodes.isEmpty {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.episodes.isEmpty, !viewModel.isSearching {
            return nil
        }
        return section == 0 ? nil : searchHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.episodes.isEmpty, !viewModel.isSearching {
            return 0
        }
        return section == 0 ? 0 : PCSearchBarController.defaultHeight
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 { return nil }
        guard tableView.isEditing, !multiSelectGestureInProgress else { return indexPath }
        if let selectedEpisode = viewModel.episodes[safe: indexPath.row], selectedEpisodes.contains(selectedEpisode) {
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        guard let selectedEpisode = viewModel.episodes[safe: indexPath.row]?.episode, let parentPodcast = selectedEpisode.parentPodcast() else { return }

        if isMultiSelectEnabled {
            let listEpisode = viewModel.episodes[indexPath.row]

            if !multiSelectGestureInProgress {
                // If the episode is already selected move to the end of the array
                selectedEpisodesRemove(uuid: listEpisode.episode.uuid)
            }

            if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: listEpisode.episode.uuid) {
                selectedEpisodes.append(listEpisode)
                // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell? {
                    cell?.showTick = true
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            let episodeController = EpisodeDetailViewController(episode: selectedEpisode, podcast: parentPodcast, source: .filters, playlist: .filter(uuid: viewModel.playlist.uuid))
            episodeController.modalPresentationStyle = .formSheet
            present(episodeController, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        guard isMultiSelectEnabled else { return }
        if let listEpisode = viewModel.episodes[safe: indexPath.row], let index = selectedEpisodes.firstIndex(of: listEpisode) {
            selectedEpisodes.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell {
                cell.showTick = false
            }
        }
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 { return false }
        return Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        isMultiSelectEnabled = true
        multiSelectGestureInProgress = true
    }

    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        multiSelectGestureInProgress = false
    }
}

extension PlaylistDetailViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .filters
    }
}
