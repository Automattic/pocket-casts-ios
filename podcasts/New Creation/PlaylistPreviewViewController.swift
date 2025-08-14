import UIKit
import Combine
import PocketCastsDataModel

enum SmartPlaylistRule: Int, CaseIterable, Identifiable {
    case podcast, episode, downloadStatus, mediaType, releaseDate, starred, duration

    var id: Int { rawValue }
}

class PlaylistPreviewViewModel: ObservableObject {
    @Published var newPlaylistHasChanged: Bool = false
    
    private(set) var isInPreview: Bool = false
    private(set) var newPlaylist: EpisodeFilter
    private(set) var enabledRules: [SmartPlaylistRule] = []
    private(set) var availableRules: [SmartPlaylistRule] = SmartPlaylistRule.allCases
    private(set) var episodes = [ListEpisode]()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init(newPlaylist: EpisodeFilter) {
        self.newPlaylist = newPlaylist
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFilterChanged(_:)),
            name: Constants.Notifications.filterChanged,
            object: nil
        )
    }

    func smartRuleIsApplied(for rule: SmartPlaylistRule) -> Bool {
        switch rule {
        case .podcast:
            return !newPlaylist.filterAllPodcasts
        case .episode:
            return !(newPlaylist.filterUnplayed && newPlaylist.filterPartiallyPlayed && newPlaylist.filterFinished)
        case .downloadStatus:
            return !(newPlaylist.filterDownloaded && newPlaylist.filterNotDownloaded)
        case .mediaType:
            return newPlaylist.filterAudioVideoType != AudioVideoFilter.all.rawValue
        case .releaseDate:
            return newPlaylist.filterHours > 0 ? true : false
        case .starred:
            return newPlaylist.filterStarred
        case .duration:
            return newPlaylist.filterDuration
        }
    }

    func hasAnyRuleApplied() -> Bool {
        for rule in SmartPlaylistRule.allCases {
            if smartRuleIsApplied(for: rule) {
                return true
            }
        }
        return false
    }

    @objc private func handleFilterChanged(_ notification: Notification) {
        guard let playlist = notification.object as? EpisodeFilter,
              playlist.uuid == newPlaylist.uuid,
              let reloadedPlaylist = DataManager.sharedManager.findFilter(uuid: newPlaylist.uuid)
        else {
            return
        }
        newPlaylist = reloadedPlaylist
        newPlaylist.isNew = true
        isInPreview = true

        enabledRules.removeAll()
        availableRules.removeAll()

        for rule in SmartPlaylistRule.allCases {
            if smartRuleIsApplied(for: rule) {
                enabledRules.append(rule)
            } else {
                availableRules.append(rule)
            }
        }

        newPlaylistHasChanged = true
    }
}

class PlaylistPreviewViewController: PCViewController {
    enum Cells {
        static let episodeCellId = "EpisodePreviewCellIdentifier"
        static let availableRulesCellIdentifier = "AvailableRulesCellIdentifier"
        static let enabledRulesCellIdentifier = "EnabledRulesCellIdentifier"
    }

    weak var delegate: FilterCreatedDelegate? // TODO: create new delegate with also a method to push the new vc from the playlists vc

    private let playlistName: String
    private var viewModel: PlaylistPreviewViewModel!
    private var cancellables = Set<AnyCancellable>()

    var previewTable: ThemeableTable! {
        didSet {
            previewTable.themeStyle = .primaryUi01
            previewTable.translatesAutoresizingMaskIntoConstraints = false
            previewTable.register(UINib(nibName: "EpisodePreviewCell", bundle: nil), forCellReuseIdentifier: Cells.episodeCellId)
            previewTable.rowHeight = UITableView.automaticDimension
            previewTable.delegate = self
            previewTable.dataSource = self
            previewTable.separatorStyle = .none
        }
    }
    private var footerView: ThemeableView! {
        didSet {
            footerView.translatesAutoresizingMaskIntoConstraints = false
            footerView.backgroundColor = AppTheme.viewBackgroundColor()
        }
    }
    private var saveButton: UIButton! {
        didSet {
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            setupSaveButtonTitle()
            saveButton.layer.cornerRadius = 12
            saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        }
    }
    private lazy var smallTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = AppTheme.colorForStyle(.primaryText01)
        l.text = playlistName
        return l
    }()

    init(playlistName: String) {
        self.playlistName = playlistName
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cancellables.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createNewPlaylist()
        setupNavBar()
        addCloseButton()
        setupContent()
    }

    private func createNewPlaylist() {
        let newPlaylist = PlaylistManager.createNewFilter()
        newPlaylist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)

        viewModel = PlaylistPreviewViewModel(newPlaylist: newPlaylist)
        viewModel.$newPlaylistHasChanged
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &cancellables)
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = playlistName

        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)

        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.titleView = smallTitleLabel

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.sizeToFit()
    }

    private func setupContent() {
        isModalInPresentation = true

        view.backgroundColor = AppTheme.viewBackgroundColor()
        
        previewTable = ThemeableTable()
        view.addSubview(previewTable)

        footerView = ThemeableView()
        view.addSubview(footerView)

        saveButton = UIButton(type: .custom)
        footerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            previewTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewTable.topAnchor.constraint(equalTo: view.topAnchor),
            previewTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewTable.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        let attributedTitle = NSAttributedString(string: "Create Smart Playlist", attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    @objc private func closeTapped() {
        presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func reloadData() {
        previewTable.reloadData()
    }

    @objc private func saveTapped() {
        viewModel.newPlaylist.syncStatus = SyncStatus.notSynced.rawValue
        viewModel.newPlaylist.isNew = false
        DataManager.sharedManager.save(filter: viewModel.newPlaylist)
        UserDefaults.standard.set(viewModel.newPlaylist.uuid, forKey: Constants.UserDefaults.lastFilterShown)
        delegate?.filterCreated(newFilter: viewModel.newPlaylist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: viewModel.newPlaylist) //TODO: remove observer before doing this
        closeTapped()

        Analytics.track(.filterCreated, properties: [
            "all_podcasts": viewModel.newPlaylist.filterAllPodcasts,
            "media_type": AudioVideoFilter(rawValue: viewModel.newPlaylist.filterAudioVideoType) ?? .all,
            "downloaded": viewModel.newPlaylist.filterDownloaded,
            "not_downloaded": viewModel.newPlaylist.filterNotDownloaded,
            "episode_status_played": viewModel.newPlaylist.filterFinished,
            "episode_status_unplayed": viewModel.newPlaylist.filterUnplayed,
            "episode_status_in_progress": viewModel.newPlaylist.filterPartiallyPlayed,
            "release_date": ReleaseDateFilterOption(rawValue: viewModel.newPlaylist.filterHours) ?? .anytime,
            "starred": viewModel.newPlaylist.filterStarred,
            "duration": viewModel.newPlaylist.filterDuration,
            "duration_longer_than": viewModel.newPlaylist.longerThan,
            "duration_shorter_than": viewModel.newPlaylist.shorterThan,
            "color": viewModel.newPlaylist.playlistColor().hexString(),
            "icon_name": viewModel.newPlaylist.iconImageName() ?? "unknown"
        ])
    }
}

extension PlaylistPreviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if viewModel.isInPreview {
            return viewModel.episodes.count // TODO: if episode count is 0 add cell with empty state
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // TODO: Display SwitUI cell with rules
        }
        if viewModel.episodes.isEmpty {
            
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.episodeCellId, for: indexPath) as! EpisodePreviewCell
        cell.style = .primaryUi01
        if let listEpisode = viewModel.episodes[safe: indexPath.row] {
            cell.populateFrom(episode: listEpisode.episode)
        }
        return cell
    }
}

extension PlaylistPreviewViewController: UITableViewDelegate {
    
}
