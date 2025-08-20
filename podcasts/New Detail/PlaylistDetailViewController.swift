import UIKit
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import DifferenceKit

class PlaylistDetailViewModel: ObservableObject {
    private(set) var playlist: EpisodeFilter!

    @Published private(set) var episodes: [ListEpisode] = []
    private(set) var firstTimeLoading = true

    private let onChange: (StagedChangeset<[ListEpisode]>, Bool) -> Void
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(playlist: EpisodeFilter, onChange: @escaping (StagedChangeset<[ListEpisode]>, Bool) -> Void) {
        self.playlist = playlist
        self.onChange = onChange
    }
    
    func update(episodes: [ListEpisode]) {
        self.episodes = episodes
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
                let changeSet = StagedChangeset(source: self.episodes, target: newData)
                self.onChange(changeSet, animated)
            }
        }
        operationQueue.addOperation(refreshOperation)
    }
}

class PlaylistDetailViewController: FakeNavViewController {
    private var viewModel: PlaylistDetailViewModel!
    private var tableView: ThemeableTable! {
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
//        let headerView = PodcastBlurHeaderView(podcastUUID: self.podcastUUID).uiView
        let headerView = UIView()
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

        tableView = ThemeableTable()
        view.insertSubview(tableView, at: 0)

        tableView.addSubview(blurHeaderView)

        loadingIndicator = ThemeLoadingIndicator()

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurHeaderView.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: PodcastHeaderView.Constants.largeImageSize),
            blurHeaderView.heightAnchor.constraint(equalTo: view.widthAnchor, constant: 40),
            blurHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            blurHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
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
                self?.reloadEmptyState()
            })
        } else {
            viewModel.update(episodes: data.last?.data ?? [])
            reloadEmptyState()
            tableView.reloadData()
        }
//        refreshMultiSelectEpisodes()
    }

    private func reloadEmptyState() {
        var config: UIContentConfiguration?

        tableView.isHidden = viewModel.episodes.isEmpty

        if viewModel.episodes.isEmpty {
            // Empty State when playlists is empty
            let title = L10n.episodeFilterNoEpisodesTitle
            let message = L10n.episodeFilterNoEpisodesMsg
            config = ContentUnavailableConfiguration.emptyState(
                title: title,
                message: message,
                icon: {
                    Image("empty-playlist-info")
                },
                actions: [
                .init(
                    title: L10n.playlistSmartRulesTitle,
                    action: { [weak self] in
//                    self?.editPlaylist()
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

    private func addObservers() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(refreshFilterFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
    }

    @objc private func refreshFilterFromNotification() {
        if viewModel.firstTimeLoading {
            loadingIndicator.startAnimating()
        }
        viewModel.reloadPlaylistAndEpisodes()
    }
    
    @objc private func refreshEpisodesFromNotification() {
        viewModel.reloadEpisodeList()
    }
}

extension PlaylistDetailViewController: UITableViewDataSource {
    private static let cellIdentifier = "EpisodeCell"

    func registerCells() {
        tableView.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: Self.cellIdentifier)
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
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as! EpisodeCell

        cell.playlist = .filter(uuid: viewModel.playlist.uuid)
//        cell.delegate = self
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
    
}
