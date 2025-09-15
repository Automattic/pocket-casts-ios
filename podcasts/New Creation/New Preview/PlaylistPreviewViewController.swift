import UIKit
import Combine
import PocketCastsDataModel
import PocketCastsUtils

class PlaylistPreviewViewController: PCViewController {
    weak var delegate: FilterCreatedDelegate?

    private let playlistName: String
    private var playlistUUID: String = ""
    private var onEditPlaylist: (() -> Void)?
    private let mode: PlaylistPreviewViewModel.PlaylistMode
    private(set) var viewModel: PlaylistPreviewViewModel!
    private var cancellables = Set<AnyCancellable>()

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
        self.mode = .creation
        super.init(nibName: nil, bundle: nil)
    }

    init(playlist: EpisodeFilter, onEditPlaylist: @escaping () -> Void) {
        self.playlistName = playlist.playlistName
        self.mode = .edit
        self.onEditPlaylist = onEditPlaylist
        super.init(nibName: nil, bundle: nil)
        self.playlistUUID = playlist.uuid
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

    override func viewWillAppear(_ animated: Bool) { }

    private func createNewPlaylist() {
        let playlist: EpisodeFilter

        switch mode {
            case .creation:
            playlist = PlaylistManager.createNewPlaylist()
            playlist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)
            playlistUUID = playlist.uuid
        case .edit:
            let result = DataManager.sharedManager.findPlaylist(uuid: playlistUUID)
            if result == nil {
                playlist = PlaylistManager.createNewPlaylist()
                playlist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)
            } else {
                playlist = result!
            }
        }

        viewModel = PlaylistPreviewViewModel(newPlaylist: playlist, playlistMode: mode) { [weak self] rule in
            self?.push(rule: rule)
        }
        viewModel.$newPlaylistHasChanged
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if self?.mode == .creation {
                    self?.updateSaveButtonEnabledState()
                } else {
                    self?.onEditPlaylist?()
                }
            }
            .store(in: &cancellables)
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = nil
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.titleView = smallTitleLabel
        navigationItem.titleView?.isHidden = true
    }

    private func setupContent() {
        isModalInPresentation = true

        view.backgroundColor = AppTheme.viewBackgroundColor()

        let list = SmartPlaylistRulesView(
            viewModel: viewModel
        ).themedUIView
        list.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(list)

        if mode == .edit {
            NSLayoutConstraint.activate([
                list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                list.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                list.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            footerView = ThemeableView()
            view.addSubview(footerView)

            saveButton = UIButton(type: .custom)
            footerView.addSubview(saveButton)

            NSLayoutConstraint.activate([
                footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                footerView.heightAnchor.constraint(equalToConstant: 110),
                footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

                saveButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
                saveButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
                saveButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -34),
                saveButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),

                list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                list.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                list.bottomAnchor.constraint(equalTo: footerView.topAnchor)
            ])
        }

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        let attributedTitle = NSAttributedString(string: L10n.playlistPreviewCreateSmartPlaylist, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    @objc private func closeTapped() {
        if viewModel.isInPreview, viewModel.playlistMode == .creation {
            PlaylistManager.delete(playlist: viewModel.newPlaylist, fireEvent: true)
        }
        dismiss()
    }

    private func dismiss() {
        if mode == .creation {
            presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }

    private func updateSaveButtonEnabledState() {
        saveButton.alpha = viewModel.isInPreview ? 1.0 : 0.4
        saveButton.isEnabled = viewModel.isInPreview
    }

    @objc private func saveTapped() {
        viewModel.newPlaylist.syncStatus = SyncStatus.notSynced.rawValue
        viewModel.newPlaylist.isNew = false
        viewModel.removeObserver()
        DataManager.sharedManager.save(playlist: viewModel.newPlaylist)
        UserDefaults.standard.set(viewModel.newPlaylist.uuid, forKey: Constants.UserDefaults.lastFilterShown)
        delegate?.filterCreated(newFilter: viewModel.newPlaylist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: viewModel.newPlaylist)

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

        dismiss()
    }

    private func push(rule: SmartPlaylistRule) {
        let viewController: UIViewController
        switch rule {
        case .podcast:
            let filterSettingsVC = PodcastFilterOverlayController(nibName: "PodcastChooserViewController", bundle: nil)
            filterSettingsVC.analyticsSource = .filters
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        case .downloadStatus:
            let filterSettingsVC = DownloadFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        case .releaseDate:
            let filterSettingsVC = ReleaseDateFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        case .mediaType:
            let filterSettingsVC = MediaFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        case .starred:
            let filterSettingsVC = StarredFilterOverlayController()
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        case .duration:
            let durationController = FilterDurationViewController(filter: viewModel.newPlaylist)
            viewController = durationController
        case .episode:
            let filterSettingsVC = EpisodeFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = viewModel.newPlaylist
            viewController = filterSettingsVC
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}
