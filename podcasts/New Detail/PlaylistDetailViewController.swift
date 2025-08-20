import UIKit
import PocketCastsDataModel

class PlaylistDetailViewController: FakeNavViewController {
    private let playlist: EpisodeFilter
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
            // TODO: Enable multi selection
//            tableView.allowsMultipleSelection = true
//            tableView.allowsMultipleSelectionDuringEditing = true
//            registerLongPress()
        }
    }
    private lazy var blurHeaderView: UIView = {
//        let headerView = PodcastBlurHeaderView(podcastUUID: self.podcastUUID).uiView
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .red
//        headerView.backgroundColor = .clear
        headerView.layer.zPosition = -1000
        headerView.isUserInteractionEnabled = false
        return headerView
    }()

    var episodes = [ListEpisode]()

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
        self.playlist = playlist

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContent()
        setupNavigation()
//        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        addObservers()
        updateColors()
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

    private func setupNavigation() {
        self.navTitle = playlist.playlistName

        addRightAction(image: UIImage(named: "more"), accessibilityLabel: L10n.learnMore, action: #selector(moreTapped))
        addGoogleCastBtn()

        closeTapped = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        }
    }

    private func setupContent() {
        view.backgroundColor = AppTheme.viewBackgroundColor()

        tableView = ThemeableTable()
        view.addSubview(tableView)

        tableView.addSubview(blurHeaderView)

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
        reloadData()

        updateNavColors(bgColor: .clear, titleColor: ThemeColor.primaryText01(), buttonColor: UIColor.white, buttonBackgroundColor: UIColor.black.withAlphaComponent(0.32))

//        multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
//        multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
//        multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
        // we need to do this for scenarios when theme was changed
        updateNavigationBar(position: tableView.contentOffset.y)
    }

    private func reloadData() {
        tableView.reloadData()
    }

    private func addObservers() {
//        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(colorsDidDownload(_:)))
//        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(hideSearchKeyboard))
//        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(upNextChanged))
//        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(upNextChanged))
//        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextChanged))
//        addCustomObserver(Constants.Notifications.searchRequested, selector: #selector(searchRequested))

        // Episode grouping can change based on download and play status, so listen for both those events and refresh when they happen
//        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodes))
//        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodes))
    }
}

extension PlaylistDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    
}
