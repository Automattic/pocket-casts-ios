import UIKit
import PocketCastsDataModel
import DifferenceKit

import SwiftUI

struct PlaylistBlurHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistDetailViewModel

    var body: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                PlaylistArtworkView(urls: viewModel.imageURLs, imageSize: 168)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                .blur(radius: 60)
                Spacer()
            }
        }
    }
}

class PlaylistDetailViewModel: ObservableObject {
    private(set) var playlist: EpisodeFilter!

    @Published private(set) var episodes: [ListEpisode] = []
    @Published var imageURLs: [URL] = []

    var isSearching = false

    private(set) var firstTimeLoading = true

    private var isLoadingImages: Bool = false
    private let imageManager: ImageManager
    private let onChange: (StagedChangeset<[ListEpisode]>, Bool) -> Void
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(
        playlist: EpisodeFilter,
        imageManager: ImageManager = .sharedManager,
        onChange: @escaping (StagedChangeset<[ListEpisode]>, Bool) -> Void
    ) {
        self.playlist = playlist
        self.imageManager = imageManager
        self.onChange = onChange
    }

    func update(episodes: [ListEpisode]) {
        self.episodes = episodes

        if isLoadingImages { return }
        isLoadingImages = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let imageURLs = try await self.loadImagesURLs(episodes: Array(episodes.prefix(4)))
                await MainActor.run {
                    self.imageURLs = imageURLs
                    self.isLoadingImages = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImages = false
                }
            }
        }
    }

    func reloadPlaylistAndEpisodes() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let reloadedPlaylist = DataManager.sharedManager.findFilter(uuid: playlist.uuid) {
                DispatchQueue.main.async { [weak self] in
                    self?.playlist = reloadedPlaylist
                }
            }
            reloadEpisodeList(animated: false)
        }
    }

    func reloadEpisodeList(animated: Bool = true) {
        if operationQueue.operationCount > 0 {
            operationQueue.cancelAllOperations()
            episodes.removeAll()
        }
        let refreshOperation = PlaylistRefreshOperation(filter: playlist) { [weak self] newData in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.firstTimeLoading {
                    self.firstTimeLoading.toggle()
                }
                let changeSet = StagedChangeset(source: self.episodes, target: newData, section: 1)
                self.onChange(changeSet, animated)
            }
        }
        operationQueue.addOperation(refreshOperation)
    }

    private func loadImagesURLs(episodes: [ListEpisode]) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL.self) { group in
            for episode in episodes {
                group.addTask {
                    if let imageUrl = try await ShowInfoCoordinator.shared.loadEpisodeArtworkUrl(podcastUuid: episode.episode.podcastUuid, episodeUuid: episode.episode.uuid),
                       let url = URL(string: imageUrl) {
                        return url
                    }
                    return self.imageManager.podcastUrl(imageSize: .grid, uuid: episode.episode.podcastUuid)
                }
            }
            var results: [URL] = []
            for try await url in group {
                results.append(url)
            }
            return results
        }
    }
}

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
            // TODO: Enable multi selection
//            tableView.allowsMultipleSelection = true
//            tableView.allowsMultipleSelectionDuringEditing = true
            registerCells()
            registerLongPress()
        }
    }
    private lazy var blurHeaderView: UIView = {
        let headerView = PlaylistBlurHeaderView(viewModel: viewModel).themedUIView
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

    var isMultiSelectEnabled = false {
        didSet {
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//
//                self.episodesTable.beginUpdates()
//                self.episodesTable.setEditing(self.isMultiSelectEnabled, animated: true)
//                if self.episodesTable.numberOfSections > 0 {
//                    self.episodesTable.reloadSections(IndexSet(integersIn: 0..<self.episodesTable.numberOfSections), with: .none)
//                }
//                self.episodesTable.endUpdates()
//                if self.isMultiSelectEnabled {
//                    if self.selectedEpisodes.count == 0, self.longPressMultiSelectIndexPath == nil, !self.multiSelectGestureInProgress {
//                        self.tableView().scrollToRow(at: IndexPath(row: NSNotFound, section: PodcastViewController.allEpisodesSection), at: .top, animated: true)
//                    }
//                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
//                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
//                        self.tableView().selectIndexPath(selectedIndexPath)
//                        self.longPressMultiSelectIndexPath = nil
//                    }
//                    if let podcast = self.podcast {
//                        if FeatureFlag.podcastViewChanges.enabled {
//                            self.multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
//                            self.multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
//                            self.multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
//                        } else {
//                            let podcastBgColor = ColorManager.backgroundColorForPodcast(podcast)
//                            self.multiSelectHeaderView.backgroundColor = ThemeColor.podcastUi05(podcastColor: podcastBgColor)
//                            self.multiSelectCancelBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
//                            self.multiSelectAllBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
//                        }
//                        self.updateSelectAllBtn()
//                        self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
//                        self.multiSelectHeaderView.isHidden = false
//                        self.view.bringSubviewToFront(self.multiSelectHeaderView)
//
//                        // Adjusts multiSelectHeaderView based on screen width
//                        self.setMultiSelectHeaderViewConstraint()
//
//                    }
//                } else {
//                    self.multiSelectHeaderView.isHidden = true
//                    self.selectedEpisodes.removeAll()
//                }
//                self.searchController?.isOverflowButtonEnabled = !self.isMultiSelectEnabled
//            }
        }
    }

    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
//    @IBOutlet var multiSelectFooter: MultiSelectFooterView! {
//        didSet {
//            multiSelectFooter.delegate = self
//        }
//    }

//    @IBOutlet var multiSelectFooterBottomConstraint: NSLayoutConstraint!
//    @IBOutlet var multiSelectAllBtn: UIButton!
//    @IBOutlet var multiSelectHeaderView: ThemeableView!

    init(playlist: EpisodeFilter) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = PlaylistDetailViewModel(playlist: playlist) { [weak self] newSet, animated in
            self?.reload(data: newSet, animated: animated)
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
//        setupRefreshControl()
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
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
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

    private func setupNavigation() {
        supportsGoogleCast = true

        navTitle = viewModel.playlist.playlistName
        scrollPointToChangeTitle = PodcastHeaderView.Constants.smallImageSize

        addRightAction(image: UIImage(named: "more"), accessibilityLabel: L10n.learnMore, action: #selector(moreTapped))
        addGoogleCastBtn()

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
            topAnchor
        ])

        view.layoutSubviews()
    }

    @objc private  func moreTapped() {

    }

    private func updateColors() {
        tableView.reloadData()

        updateNavColors(bgColor: .clear, titleColor: ThemeColor.primaryText01(), buttonColor: UIColor.white, buttonBackgroundColor: UIColor.black.withAlphaComponent(0.32))

//        multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
//        multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
//        multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
        // we need to do this for scenarios when theme was changed
        updateNavigationBar(position: tableView.contentOffset.y)
    }

    private func reload(data: StagedChangeset<[ListEpisode]>, animated: Bool = true) {
        if animated {
            tableView.reload(using: data, with: .none, setData: { [weak self] episodes in
                self?.viewModel.update(episodes: episodes)
                // reload header
                self?.reloadEmptyState()
            })
        } else {
            viewModel.update(episodes: data.last?.data ?? [])
            reloadEmptyState()
            tableView.reloadData()
        }
//        refreshMultiSelectEpisodes()
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
}

extension PlaylistDetailViewController: UITableViewDataSource {
    private static let cellIdentifier = "EpisodeCell"

    func registerCells() {
        tableView.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: Self.cellIdentifier)
        tableView.register(EmptyStateCell.self, forCellReuseIdentifier: EmptyStateCell.reuseIdentifier)
    }

    func registerLongPress() {
//        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
//        tableView.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
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
            let cell = UITableViewCell()
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            return cell
        }

        if viewModel.isSearching, viewModel.episodes.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
            cell.configure(title: L10n.discoverNoEpisodesFound, message: L10n.discoverNoPodcastsFoundMsg) {
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
//            if isMultiSelectEnabled {
//                cell.showTick = selectedEpisodesContains(uuid: listEpisode.episode.uuid)
//            }
        }
        return cell
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.episodes.isEmpty {
            return 0
        }
        return indexPath.section == 0 ? 335 : UITableView.automaticDimension
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
}
