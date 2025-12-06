import SwiftUI
import UIKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import Combine

class PlaylistsViewController: PCViewController, FilterCreatedDelegate {
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
        }
    }

    var playlists = [EpisodeFilter]() {
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

    private var cancellables: Set<AnyCancellable> = []

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
        if FeatureFlag.playlistsRebranding.enabled {
            addReloadPlaylistsObservers()
        } else {
            setupNewFilterButton()
        }
        handleThemeChanged()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if FeatureFlag.playlistsRebranding.enabled {
            if firstTimeLoading {
                reloadFilters()
            }
        } else {
            reloadFilters()
        }
        setupInformationalBanner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavTintColors()
        if !FeatureFlag.playlistsRebranding.enabled {
            addCustomObserver(Constants.Notifications.playlistChanged, selector: #selector(filtersUpdated))
        }
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        Analytics.track(.filterListShown, properties: ["filter_count": playlists.count])

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
            playlists = DataManager.sharedManager.allPlaylists(includeDeleted: false)
            firstTimeLoading = false
            DispatchQueue.main.async {
                self.newFilterButton.isHidden = false
                self.loadingIndicator.stopAnimating()
                self.filtersTable.reloadData()
            }
        }
    }

    private func addReloadPlaylistsObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(filtersUpdated), name: Constants.Notifications.playlistChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(filtersUpdated), name: Constants.Notifications.playlistsNeedReload, object: nil)

        if FeatureFlag.refreshPlaylistOnSubscriptions.enabled {
            let deleted = NotificationCenter.default.publisher(for: Constants.Notifications.podcastDeleted)
            let added = NotificationCenter.default.publisher(for: Constants.Notifications.podcastAdded)

            Publishers.Merge(deleted, added).debounce(for: 0.5, scheduler: DispatchQueue.main).sink { [weak self] _ in
                self?.filtersUpdated()
            }
            .store(in: &cancellables)
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

        customRightBtn?.isHidden = playlists.isEmpty

        var config: UIContentConfiguration?

        if playlists.isEmpty {
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

    // MARK: - FilterCreationDelegate

    func filterCreated(newFilter: EpisodeFilter) {
        showFilter(newFilter, isNew: true)
    }
}
