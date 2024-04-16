import PocketCastsServer
import UIKit
import PocketCastsUtils

class DiscoverViewController: PCViewController {
    @IBOutlet var mainScrollView: UIScrollView!

    @IBOutlet var noResultsView: UIView!
    @IBOutlet var infoHeaderLabel: UILabel!
    @IBOutlet var infoDetailLabel: UILabel!

    @IBOutlet var noNetworkView: UIView!
    @IBOutlet var noInternetImage: UIImageView!

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    private let sectionPadding = 16 as CGFloat

    private var summaryViewControllers = [(item: DiscoverItem, viewController: UIViewController)]()

    var searchController: PCSearchBarController!

    lazy var searchResultsController = SearchResultsViewController(source: .discover)

    var resultsControllerDelegate: SearchResultsDelegate {
        searchResultsController
    }

    private var loadingContent = false

    var discoverLayout: DiscoverLayout?

    private let coordinator: DiscoverCoordinator

    init(coordinator: DiscoverCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.discover

        handleThemeChanged()
        reloadData()
        setupSearchBar()

        addCustomObserver(Constants.Notifications.chartRegionChanged, selector: #selector(chartRegionDidChange))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AnalyticsHelper.navigatedToDiscover()
        Analytics.track(.discoverShown)

        reloadIfRequired()

        NotificationCenter.default.addObserver(self, selector: #selector(searchRequested), name: Constants.Notifications.searchRequested, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.navigationBar.shadowImage = nil

        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.searchRequested, object: nil)
    }

    @objc private func checkForScrollTap(_ notification: Notification) {
        guard let index = notification.object as? Int, index == tabBarItem.tag else { return }

        let defaultOffset = -PCSearchBarController.defaultHeight - view.safeAreaInsets.top
        if mainScrollView.contentOffset.y.rounded(.down) > defaultOffset.rounded(.down) {
            mainScrollView.setContentOffset(CGPoint(x: 0, y: defaultOffset), animated: true)
        } else {
            searchController.searchTextField.becomeFirstResponder()
        }
    }

    @objc private func searchRequested() {
        mainScrollView.setContentOffset(CGPoint(x: 0, y: -PCSearchBarController.defaultHeight - view.safeAreaInsets.top), animated: false)
        searchController.searchTextField.becomeFirstResponder()
    }

    @objc private func chartRegionDidChange() {
        reloadData()
    }

    private func addCommonConstraintsFor(_ viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor).isActive = true
        viewController.view.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor).isActive = true
        viewController.view.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor).isActive = true
    }

    override func handleThemeChanged() {
        mainScrollView.backgroundColor = ThemeColor.primaryUi02()
    }

    // MARK: - UI Actions

    @IBAction func reloadDiscoverTapped(_ sender: AnyObject) {
        reloadData()
    }

    // MARK: - Data Loading

    private func reloadData() {
        showPageLoading()

        DiscoverServerHandler.shared.discoverPage { [weak self] discoverLayout, _ in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.populateFrom(discoverLayout: discoverLayout)
            }
        }
    }

    private func reloadIfRequired() {
        if loadingContent { return }

        DiscoverServerHandler.shared.discoverPage { [weak self] discoverLayout, cachedResponse in
            if cachedResponse { return } // we got back a cached response, no need to reload the page

            DispatchQueue.main.async {
                guard let self = self else { return }

                self.showPageLoading()
                self.populateFrom(discoverLayout: discoverLayout)
            }
        }
    }

    /// Reloads discover, keeping the items listed in `exclude`
    /// - Parameters:
    ///   - items: Items to exclude from the reload process. These items will REMAIN in Discover
    ///   - category: The `DiscoverCategory` to add to the layout. This is sort of an artifical `DiscoverLayout`.
    func reload(except items: [DiscoverItem], category: DiscoverCategory) {
        let region = discoverLayout.map { Settings.discoverRegion(discoverLayout: $0) }
        let categoryVC = CategoryPodcastsViewController(category: category, region: region)
        categoryVC.delegate = self
        categoryVC.view.alpha = 0

        let item = DiscoverItem(id: "category-\(category.id ?? 0)", title: category.name, source: category.source, regions: items.first?.regions ?? [])
        populateFrom(discoverLayout: discoverLayout, shouldInclude: {
            ($0.categoryID == category.id) || items.contains($0)
        }, shouldReset: {
            !items.contains($0)
        })
        addToScrollView(viewController: categoryVC, for: item, isLast: true)
        categoryVC.podcastsTable.isScrollEnabled = false
    }

    private func showPageLoading() {
        loadingContent = true

        mainScrollView.isHidden = true
        noNetworkView.isHidden = true
        noResultsView.isHidden = true

        loadingIndicator.startAnimating()
    }

    private var currentSnapshot: NSDiffableDataSourceSnapshot<Int, DiscoverItem>?

    private func resetSummaryViewControllers(filter: ((DiscoverItem) -> Bool)?) {
        let viewsToRemove = summaryViewControllers.filter { sumItem in
            filter?(sumItem.item) ?? true
        }

        UIView.animate(withDuration: 0.1) {
            viewsToRemove.forEach { $0.viewController.view.alpha = 0 }
        } completion: { [self] _ in
            viewsToRemove.forEach { _, vc in
                vc.willMove(toParent: nil)
                vc.view.alpha = 0
                NSLayoutConstraint.deactivate(vc.view.constraints)
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }

            UIView.animate(withDuration: 0.2) { [self] in
                summaryViewControllers.forEach {
                    $0.viewController.view.alpha = 1
                }
            }
        }

        summaryViewControllers.removeAll { sumItem in
            filter?(sumItem.item) ?? true
        }
    }

    private func apply(snapshot: NSDiffableDataSourceSnapshot<Int, DiscoverItem>, currentRegion: String) {
        for discoverItem in snapshot.itemIdentifiers {
            guard let type = discoverItem.type, let summaryStyle = discoverItem.summaryStyle else { continue }
            let expandedStyle = discoverItem.expandedStyle ?? ""

            guard coordinator.shouldDisplay(discoverItem) else { continue }

            guard summaryViewControllers.contains(where: { $0.item == discoverItem }) == false else { continue }

            switch (type, summaryStyle, expandedStyle) {
            case ("categories", "pills", _):
                addSummaryController(CategoriesSelectorViewController(), discoverItem: discoverItem)
            case ("podcast_list", "carousel", _):
                addSummaryController(FeaturedSummaryViewController(), discoverItem: discoverItem)
            case ("podcast_list", "small_list", _):
                addSummaryController(SmallPagedListSummaryViewController(), discoverItem: discoverItem)
            case ("podcast_list", "large_list", _):
                addSummaryController(LargeListSummaryViewController(), discoverItem: discoverItem)
            case ("podcast_list", "single_podcast", _):
                addSummaryController(SinglePodcastViewController(), discoverItem: discoverItem)
            case ("podcast_list", "collection", _):
                addSummaryController(CollectionSummaryViewController(), discoverItem: discoverItem)
            case ("network_list", _, _):
                addSummaryController(NetworkSummaryViewController(), discoverItem: discoverItem)
            case ("categories", "category", _):
                addSummaryController(CategorySummaryViewController(regionCode: currentRegion), discoverItem: discoverItem)
            case ("episode_list", "single_episode", _):
                addSummaryController(SingleEpisodeViewController(), discoverItem: discoverItem)
            case ("episode_list", "collection", "plain_list"):
                addSummaryController(CollectionSummaryViewController(), discoverItem: discoverItem)
            default:
                print("Unknown Discover Item: \(type) \(summaryStyle)")
                continue
            }
        }
        currentSnapshot = snapshot
    }

    /// Populate the scroll view using a DiscoverLayout with optional shouldInclude and shouldReset filters.
    /// - Parameters:
    ///   - discoverLayout: A `DiscoverLayout`
    ///   - shouldInclude: Whether a `DiscoverItem` from the layout should be included in the scroll view. This is used to filter items meant only for certain categories, for instance.
    ///   - shouldReset: Whether a view controller from `summaryViewControllers` should be reset during this operation. This is used by the Categories pills to avoid triggering a view reload, allowing animations to continue.
    private func populateFrom(discoverLayout: DiscoverLayout?, shouldInclude: ((DiscoverItem) -> Bool)? = nil, shouldReset: ((DiscoverItem) -> Bool)? = nil) {
        loadingContent = false

        guard let layout = discoverLayout, let items = layout.layout, let _ = layout.regions, items.count > 0 else {
            handleLoadFailed()
            return
        }

        self.discoverLayout = layout
        loadingIndicator.stopAnimating()

        let currentRegion = Settings.discoverRegion(discoverLayout: layout)

        func makeDataSourceSnapshot(from items: [DiscoverItem]) -> NSDiffableDataSourceSnapshot<Int, DiscoverItem> {
            var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverItem>()

            let section = 0
            snapshot.appendSections([section])
            snapshot.appendItems(items.filter({ shouldInclude?($0) ?? true }))

            return snapshot
        }

        let snapshot = makeDataSourceSnapshot(from: items)
        resetSummaryViewControllers {
            shouldReset?($0) ?? true
        }
        apply(snapshot: snapshot, currentRegion: currentRegion)

        let regions = layout.regions?.keys as? [String]
        let item = DiscoverItem(id: "country-summary", regions: regions ?? [])

        if shouldInclude?(item) ?? true {
            let countrySummary = CountrySummaryViewController()
            countrySummary.discoverLayout = layout
            countrySummary.registerDiscoverDelegate(self)
            addToScrollView(viewController: countrySummary, for: item, isLast: true)
        }

        mainScrollView.isHidden = false
        noNetworkView.isHidden = true
    }

    private func addSummaryController(_ controller: DiscoverSummaryProtocol, discoverItem: DiscoverItem) {
        guard let viewController = controller as? UIViewController else { return }

        viewController.view.alpha = 0
        addToScrollView(viewController: viewController, for: discoverItem, isLast: false)

        controller.registerDiscoverDelegate(self)
        controller.populateFrom(item: discoverItem)
    }

    private func addToScrollView(viewController: UIViewController, for item: DiscoverItem, isLast: Bool) {
        mainScrollView.addSubview(viewController.view)
        addCommonConstraintsFor(viewController)

        // anchor the bottom view to the bottom, the middle ones to each other, and the last one to the bottom and the one above it
        if isLast {
            if let previousView = summaryViewControllers.last?.viewController.view {
                viewController.view.topAnchor.constraint(equalTo: previousView.bottomAnchor).isActive = true
            }
            viewController.view.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor, constant: -65).isActive = true
        } else if let previousVC = summaryViewControllers.last?.viewController, let previousView = previousVC.view {
            if previousVC is FeaturedSummaryViewController {
                viewController.view.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: -10).isActive = true
                mainScrollView.sendSubviewToBack(viewController.view)
            } else {
                viewController.view.topAnchor.constraint(equalTo: previousView.bottomAnchor).isActive = true
            }
        } else {
            viewController.view.topAnchor.constraint(equalTo: mainScrollView.topAnchor).isActive = true
        }

        summaryViewControllers.append((item, viewController))
        addChild(viewController)
    }

    private func handleLoadFailed() {
        loadingIndicator.stopAnimating()
        noNetworkView.isHidden = false
    }
}

// MARK: - Analytics

extension DiscoverViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .discover
    }
}

extension DiscoverItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(uuid)
    }
}
