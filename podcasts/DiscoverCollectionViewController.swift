import PocketCastsServer
import PocketCastsUtils

class DiscoverCollectionViewController: PCViewController, UICollectionViewDelegate {

    typealias Section = Int
    typealias Item = DiscoverItem

    private(set) lazy var collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let coordinator: DiscoverCoordinator
    private var loadingContent = false
    private(set) var discoverLayout: DiscoverLayout?

    private(set) lazy var searchController: PCSearchBarController = {
        PCSearchBarController()
    }()
    lazy var searchResultsController = SearchResultsViewController(source: .discover)

    var resultsControllerDelegate: SearchResultsDelegate {
        searchResultsController
    }

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

        setupCollectionView()
        setupSearchBar()

        reloadData()

//        addCustomObserver(Constants.Notifications.chartRegionChanged, selector: #selector(chartRegionDidChange))
//        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
//
//        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
//        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AnalyticsHelper.navigatedToDiscover()
        Analytics.track(.discoverShown)

        miniPlayerStatusDidChange()
    }

    func reloadData() {
        showPageLoading()

        DiscoverServerHandler.shared.discoverPage { [weak self] discoverLayout, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.populateFrom(discoverLayout: discoverLayout)
            }
        }
    }

    private func populateFrom(discoverLayout: DiscoverLayout?, shouldInclude: ((DiscoverItem) -> Bool)? = nil) {
        loadingContent = false

        guard let discoverLayout, let items = discoverLayout.layout, let _ = discoverLayout.regions, items.count > 0 else {
            handleLoadFailed()
            return
        }

        let itemFilter = shouldInclude ?? { item in
            item.categoryID == nil
        }

        self.discoverLayout = discoverLayout

        configureDataSource()

        collectionView.collectionViewLayout = createCompositionalLayout(with: discoverLayout)

        let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)

        let snapshot = discoverLayout.layout?.makeDataSourceSnapshot(region: currentRegion, itemFilter: itemFilter)

        if let snapshot {
            dataSource.apply(snapshot)
        }
    }

    private func showPageLoading() {
        //TODO: Imlement this in a separate PR
    }

    private func handleLoadFailed() {
        //TODO: Implement this in a separate PR
    }
}

extension DiscoverCollectionViewController {
    private func setupCollectionView() {
        let layout = createCompositionalLayout(with: discoverLayout)
        collectionView.collectionViewLayout = layout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        let viewControllerCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, DiscoverItem> { cell, indexPath, item in
              //TODO: Change this to be passed in by `item`
           let currentRegion = Settings.discoverRegion(discoverLayout: self.discoverLayout!)
            guard let vc = item.viewController(in: currentRegion) else { return }

            cell.contentConfiguration = UIViewControllerContentConfiguration(viewController: vc)

            vc.registerDiscoverDelegate(self)
            vc.populateFrom(item: item, region: currentRegion, category: nil)
        }

        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] supplementaryView, elementKind, indexPath in

            guard let self else { return }

            let countrySummary = CountrySummaryViewController()
            countrySummary.discoverLayout = self.discoverLayout
            countrySummary.registerDiscoverDelegate(self)

            supplementaryView.contentConfiguration = UIViewControllerContentConfiguration(viewController: countrySummary)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: viewControllerCellRegistration, for: indexPath, item: item)
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration,
                                                                         for: indexPath)
        }
    }

    private func createCompositionalLayout(with layout: DiscoverLayout?) -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                      layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(100))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(100))
            let group: NSCollectionLayoutGroup
            if #available(iOS 16, *) {
                group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: layout?.layout?.count ?? 0)
            } else {
                group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: layout?.layout?.map({ _ in item }) ?? [])
            }

            let section = NSCollectionLayoutSection(group: group)

            // Create a size for the header accessory view
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(44))

            // Create a boundary supplementary item for the footer
            let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )

            // Add the header to the section's boundary supplementary items
            section.boundarySupplementaryItems = [sectionFooter]

            return section
        }
    }
}

extension DiscoverCollectionViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .discover
    }
}

private extension DiscoverItem {
    func viewController(in region: String) -> (UIViewController & DiscoverSummaryProtocol)? {
        switch (type, summaryStyle, expandedStyle) {
        case ("categories", "pills", _):
            return CategoriesSelectorViewController()
        case ("podcast_list", "carousel", _):
            return FeaturedSummaryViewController()
        case ("podcast_list", "small_list", _):
            return SmallPagedListSummaryViewController()
        case ("podcast_list", "large_list", _):
            return LargeListSummaryViewController()
        case ("podcast_list", "single_podcast", _):
            return SinglePodcastViewController()
        case ("podcast_list", "collection", _):
            return CollectionSummaryViewController()
        case ("network_list", _, _):
            return NetworkSummaryViewController()
        case ("categories", "category", _):
            return CategorySummaryViewController(regionCode: region)
        case ("episode_list", "single_episode", _):
            return SingleEpisodeViewController()
        case ("episode_list", "collection", "plain_list"):
            return CollectionSummaryViewController()
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type) \(summaryStyle)")
            return nil
        }
    }
}

extension DiscoverCollectionViewController {
    @objc func miniPlayerStatusDidChange() {
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        collectionView.contentInset = UIEdgeInsets(top: PCSearchBarController.defaultHeight, left: 0, bottom: miniPlayerOffset, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerOffset, right: 0)
    }
}
