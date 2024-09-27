import PocketCastsServer

class DiscoverCollectionViewController: PCViewController {

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

        setupMiniPlayerObservers()
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

// MARK: - Collection View
extension DiscoverCollectionViewController {
    private func setupCollectionView() {
        let layout = createCompositionalLayout(with: discoverLayout)
        collectionView.collectionViewLayout = layout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] supplementaryView, elementKind, indexPath in

            guard let self else { return }

            let countrySummary = CountrySummaryViewController()
            countrySummary.discoverLayout = self.discoverLayout
            countrySummary.registerDiscoverDelegate(self)

            supplementaryView.contentConfiguration = UIViewControllerContentConfiguration(viewController: countrySummary)
        }

        let currentRegion = Settings.discoverRegion(discoverLayout: self.discoverLayout!)

        let registrations: [DiscoverCellType: UICollectionView.CellRegistration] = DiscoverCellType.allCases.reduce(into: [:]) { partialResult, cellType in
            partialResult[cellType] = cellType.createCellRegistration(region: currentRegion, delegate: self)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self, let cellType = item.cellType() else { return UICollectionViewCell() }
            let cellRegistration = registrations[cellType]!
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
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

            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(44))

            let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )

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

// MARK: - Mini Player
extension DiscoverCollectionViewController {
    fileprivate func setupMiniPlayerObservers() {
        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
    }

    @objc func miniPlayerStatusDidChange() {
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        collectionView.contentInset = UIEdgeInsets(top: PCSearchBarController.defaultHeight, left: 0, bottom: miniPlayerOffset, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerOffset, right: 0)
    }
}
