import PocketCastsServer
import SwiftUI
import PocketCastsUtils

class DiscoverCollectionViewController: PCViewController {

    enum CellType: Hashable {
        case loading(String?)
        case noNetwork
        case noResults
        case empty
        case item(DiscoverCellType.ItemType)
    }

    typealias Section = Int
    typealias Item = CellType

    private(set) lazy var collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }()

    private(set) var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let coordinator: DiscoverCoordinator
    private var loadingContent = false
    private(set) var discoverLayout: DiscoverLayout?
    fileprivate var selectedCategory: DiscoverCategory?
    private var loadingTasks: [String: Task<Void, Never>] = [:]

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

        handleThemeChanged()
        setupCollectionView()
        setupSearchBar()

        configureDataSource()
        reloadData()

        setupMiniPlayerObservers()
        setupLoginObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AnalyticsHelper.navigatedToDiscover()
        Analytics.track(.discoverShown)

        miniPlayerStatusDidChange()
    }

    func reloadData(completion: (() -> Void)? = nil) {
        showPageLoading()

        DiscoverServerHandler.shared.discoverPage { [weak self] discoverLayout, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.populateFrom(discoverLayout: discoverLayout)
                completion?()
            }
        }
    }

    override func handleThemeChanged() {
        collectionView.backgroundColor = ThemeColor.primaryUi02()
        collectionView.reloadData()
    }

    private func checkSourceAuthentication(for item: DiscoverItem) async -> Bool {
        return await DiscoverServerHandler.shared.checkSourceAuthentication(for: item)
    }

    func populateFrom(discoverLayout: DiscoverLayout?, selectedCategory: DiscoverCategory? = nil, shouldInclude: ((DiscoverItem) -> Bool)? = nil) {
        self.selectedCategory = selectedCategory
        loadingContent = false

        guard let discoverLayout, let items = discoverLayout.layout, let _ = discoverLayout.regions else {
            handleLoadFailed()
            return
        }

        guard items.count > 0 else {
            handleEmptyResults()
            return
        }

        let itemFilter = shouldInclude ?? { item in
            item.categoryID == nil && item.shouldShowAuthenticated()
        }

        self.discoverLayout = discoverLayout

        let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)

        if FeatureFlag.recommendations.enabled {
            var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
            snapshot.appendSections([0])

            loadingTasks.values.forEach { $0.cancel() }
            loadingTasks = [:]

            for item in items {
                let selectedCategory = item.cellType() != .categoriesSelector ? selectedCategory : nil

                if itemFilter(item) && item.regions.contains(currentRegion) {
                    if item.authenticated == true, let uuid = item.uuid {
                        snapshot.appendItems([.loading(uuid)])
                        loadingTasks[uuid] = Task { [weak self] in
                            guard let self, !Task.isCancelled else { return }
                            let isAuthenticated = await self.checkSourceAuthentication(for: item)
                            guard !Task.isCancelled else { return }
                            self.updateItemInSnapshot(item: item, isAuthenticated: isAuthenticated, region: currentRegion, selectedCategory: selectedCategory)
                            self.loadingTasks.removeValue(forKey: uuid)
                        }
                    } else {
                        let model = DiscoverCellModel(item: item, region: currentRegion, selectedCategory: selectedCategory)
                        if let cellType = item.cellType() {
                            snapshot.appendItems([.item(DiscoverCellType.ItemType(cellType: cellType, model: model))])
                        }
                    }
                }
            }

            dataSource.apply(snapshot)
        } else {
            let snapshot = discoverLayout.layout?.makeDataSourceSnapshot(region: currentRegion, selectedCategory: selectedCategory, itemFilter: itemFilter)
            if let snapshot {
                dataSource.apply(snapshot)
            }
        }
    }

    private func updateItemInSnapshot(item: DiscoverItem, isAuthenticated: Bool, region: String, selectedCategory: DiscoverCategory?) {
        var snapshot = dataSource.snapshot()

        // Find the loading placeholder for this specific item using its UUID
        let items = snapshot.itemIdentifiers(inSection: 0)
        if let loadingItem = items.first(where: {
            if case .loading(let uuid) = $0, uuid == item.uuid { return true }
            return false
        }) {
            // Replace the loading placeholder with either the authenticated item or empty
            if isAuthenticated {
                let model = DiscoverCellModel(item: item, region: region, selectedCategory: selectedCategory)
                if let cellType = item.cellType() {
                    let newItem = CellType.item(DiscoverCellType.ItemType(cellType: cellType, model: model))
                    snapshot.insertItems([newItem], beforeItem: loadingItem)
                }
            } else {
                snapshot.insertItems([.empty], beforeItem: loadingItem)
            }
            snapshot.deleteItems([loadingItem])

            dataSource.apply(snapshot)
        }
    }

    private func showPageLoading() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([CellType.loading(nil)])
        dataSource.apply(snapshot)
    }

    private func handleLoadFailed() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([CellType.noNetwork])
        dataSource.apply(snapshot)
    }

    private func handleEmptyResults() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([CellType.noResults])
        dataSource.apply(snapshot)
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }
}

// MARK: - Collection View
extension DiscoverCollectionViewController {
    private func setupCollectionView() {
        let layout = createCompositionalLayout()
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

        let footerRegistrationCountrySummary = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }

            let countrySummary = CountrySummaryViewController()
            countrySummary.discoverLayout = self.discoverLayout
            countrySummary.registerDiscoverDelegate(self)

            supplementaryView.contentConfiguration = UIViewControllerContentConfiguration(parentViewController: self, viewController: countrySummary)
        }

        let footerRegistrationEmpty = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
            supplementaryView.contentConfiguration = UIHostingConfiguration {
                EmptyView()
            }
        }

        let registrations: [DiscoverCellType: UICollectionView.CellRegistration] = DiscoverCellType.allCases.reduce(into: [:]) { partialResult, cellType in
            partialResult[cellType] = cellType.createCellRegistration(parentViewController: self, delegate: self)
        }

        let loadingRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, indexPath, item in
            cell.contentConfiguration = ContentUnavailableConfiguration.loading()
        }

        let noNetworkRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, indexPath, item in
            cell.contentConfiguration = ContentUnavailableConfiguration.noNetwork { [weak self] in
                self?.reloadData()
            }
        }

        let noResultsRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, indexPath, item in
            cell.contentConfiguration = ContentUnavailableConfiguration.noResults()
        }

        let emptyRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, indexPath, item in
            cell.contentConfiguration = ContentUnavailableConfiguration.empty()
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .loading:
                return collectionView.dequeueConfiguredReusableCell(using: loadingRegistration, for: indexPath, item: item)
            case .noNetwork:
                return collectionView.dequeueConfiguredReusableCell(using: noNetworkRegistration, for: indexPath, item: item)
            case .noResults:
                return collectionView.dequeueConfiguredReusableCell(using: noResultsRegistration, for: indexPath, item: item)
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(using: emptyRegistration, for: indexPath, item: item)
            case .item(let item):
                let cellRegistration = registrations[item.cellType]!
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let self = self else { return nil }

            if elementKind == UICollectionView.elementKindSectionFooter {
                if self.selectedCategory == nil && self.discoverLayout != nil {
                    return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistrationCountrySummary, for: indexPath)
                } else {
                    return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistrationEmpty, for: indexPath)
                }
            }
            return nil
        }
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int,
                                                      layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: self?.discoverLayout == nil ? .fractionalHeight(0.8) : .estimated(100))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: itemSize.widthDimension,
                                                   heightDimension: itemSize.heightDimension)
            let group: NSCollectionLayoutGroup
            group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

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

// MARK: - Authentication Handling
extension DiscoverCollectionViewController {
    fileprivate func setupLoginObserver() {
        // Add observer for login/logout notification
        NotificationCenter.default.addObserver(forName: .userLoginDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.reloadData()
        }
    }
}
