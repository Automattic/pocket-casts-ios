import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class PlaylistsViewController: PCViewController, FilterCreatedDelegate {
    @IBOutlet var filtersTable: UITableView! {
        didSet {
            registerCells()
            if FeatureFlag.playlistsRebranding.enabled {
                filtersTable.separatorStyle = .none
            }
        }
    }

    var playlists = [EpisodeFilter]()

    var sourceIndexPath: IndexPath?
    var snapshot: UIView?
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
        let viewModel = InformationalBannerViewModel(bannerType: .filters)
        return InformationalBannerViewCoordinator(viewModel: viewModel)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if FeatureFlag.playlistsRebranding.enabled {
            customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(editTapped))
        } else {
            customRightBtn = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        }
        customRightBtn?.accessibilityLabel = L10n.accessibilityMoreActions

        title = FeatureFlag.playlistsRebranding.enabled ? L10n.playlists : L10n.filters

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            if let lastFilterUuid = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastFilterShown), let filter = DataManager.sharedManager.findFilter(uuid: lastFilterUuid) {
                DispatchQueue.main.async {
                    let playlistViewController = PlaylistViewController(filter: filter)
                    self.navigationController?.pushViewController(playlistViewController, animated: false)
                }
            }

        }

        loadingIndicator = ThemeLoadingIndicator()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: filtersTable)
        if FeatureFlag.playlistsRebranding.enabled {
            
        } else {
            setupNewFilterButton()
        }
        handleThemeChanged()
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
        reloadFilters()
        setupInformationalBanner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavTintColors()
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(filtersUpdated))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        Analytics.track(.filterListShown, properties: ["filter_count": playlists.count])

        showNewFilterTipIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        navigationController?.navigationBar.shadowImage = nil
    }

    @objc private func editTapped() {
        filtersTable.isEditing = !filtersTable.isEditing
        filtersTable.reloadData() // this is needed to ensure the cell re-arrange controls are tinted correctly
        if FeatureFlag.playlistsRebranding.enabled {
            if filtersTable.isEditing {
                customRightBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editTapped))
            } else {
                customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(editTapped))
            }
        } else {
            customRightBtn = UIBarButtonItem(barButtonSystemItem: filtersTable.isEditing ? .done : .edit, target: self, action: #selector(editTapped))
        }
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
        reloadFilters()
    }

    @IBAction func addNewFilter() {
        Analytics.track(.filterCreateButtonTapped)
        let createFilterVC = FilterPreviewViewController()
        createFilterVC.delegate = self
        let navVC = SJUIUtils.navController(for: createFilterVC)
        present(navVC, animated: true, completion: nil)
    }

    override func handleThemeChanged() {
        filtersTable.reloadData()
        updateNavTintColors()
        newFilterButton.layer.borderColor = ThemeColor.primaryInteractive01().cgColor
        newFilterButton.titleLabel?.textColor = ThemeColor.primaryInteractive01()
    }

    private func updateNavTintColors() {
        changeNavTint(titleColor: AppTheme.navBarTitleColor(), iconsColor: AppTheme.navBarIconsColor())
    }

    func showFilter(_ filter: EpisodeFilter, isNew: Bool? = false) {
        let playlistViewController = PlaylistViewController(filter: filter)
        playlistViewController.isNewFilter = isNew ?? false
        navigationController?.popToRootViewController(animated: false)
        navigationController?.pushViewController(playlistViewController, animated: true)

        UserDefaults.standard.set(filter.uuid, forKey: Constants.UserDefaults.lastFilterShown)
    }

    private func reloadFilters() {
        if firstTimeLoading {
            loadingIndicator.startAnimating()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            playlists = DataManager.sharedManager.allFilters(includeDeleted: false)
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
        filtersTable.tableHeaderView = informationalBannerCoordinator.tableHeaderView(size: CGSize(width: filtersTable.bounds.width, height: 160)) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.filtersTable.tableHeaderView = nil
            }
        }
    }

    // MARK: - FilterCreationDelegate

    func filterCreated(newFilter: EpisodeFilter) {
        showFilter(newFilter, isNew: true)
    }
}
