import PocketCastsServer
import SwiftUI

class DiscoverCollectionViewController: PCViewController {

    typealias Section = Int
    typealias Item = DiscoverCellType.ItemType

    private(set) lazy var collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }()

    private(set) var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let coordinator: DiscoverCoordinator
    private var loadingContent = false
    private(set) var discoverLayout: DiscoverLayout?
    fileprivate var selectedCategory: DiscoverCategory?

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

        configureDataSource()
        reloadData()

        setupMiniPlayerObservers()
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

    func populateFrom(discoverLayout: DiscoverLayout?, selectedCategory: DiscoverCategory? = nil, shouldInclude: ((DiscoverItem) -> Bool)? = nil) {
        self.selectedCategory = selectedCategory
        loadingContent = false

        guard let discoverLayout, let items = discoverLayout.layout, let _ = discoverLayout.regions, items.count > 0 else {
            handleLoadFailed()
            return
        }

        let itemFilter = shouldInclude ?? { item in
            item.categoryID == nil
        }

        self.discoverLayout = discoverLayout

        let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)
        let snapshot = discoverLayout.layout?.makeDataSourceSnapshot(region: currentRegion, selectedCategory: selectedCategory, itemFilter: itemFilter)
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
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] supplementaryView, elementKind, indexPath in

            guard let self else { return }

            if selectedCategory == nil {
                let countrySummary = CountrySummaryViewController()
                countrySummary.discoverLayout = self.discoverLayout
                countrySummary.registerDiscoverDelegate(self)

                supplementaryView.contentConfiguration = UIViewControllerContentConfiguration(viewController: countrySummary)
            } else {
                if #available(iOS 16.0, *) {
                    supplementaryView.contentConfiguration = UIHostingConfiguration {
                        EmptyView()
                    }
                } else {
                    supplementaryView.contentConfiguration = UIListContentConfiguration.plainFooter()
                }
            }
        }

        let registrations: [DiscoverCellType: UICollectionView.CellRegistration] = DiscoverCellType.allCases.reduce(into: [:]) { partialResult, cellType in
            partialResult[cellType] = cellType.createCellRegistration(delegate: self)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            guard let cellType = item.item.cellType() else { return UICollectionViewCell() }
            let cellRegistration = registrations[cellType]!
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration,
                                                                         for: indexPath)
        }
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                      layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(100))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(100))
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
