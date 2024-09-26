import UIKit
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

protocol SnakeCaseRepresentable: RawRepresentable where RawValue == String {
    static func snakeCasedString(from string: String) -> String
    init?(snakeCasedRawValue: String)
}

extension SnakeCaseRepresentable {
    static func snakeCasedString(from string: String) -> String {
        var result = ""
        for character in string {
            if character.isUppercase {
                // Add an underscore before uppercase letters, except for the first character
                if !result.isEmpty {
                    result += "_"
                }
                result += character.lowercased()
            } else {
                result += String(character)
            }
        }
        return result
    }

    var snakeCasedRawValue: String {
        return Self.snakeCasedString(from: String(describing: self))
    }

    init?(snakeCasedRawValue: String) {
        let camelCasedString = Self.camelCasedString(from: snakeCasedRawValue)
        self.init(rawValue: camelCasedString)
    }

    private static func camelCasedString(from snakeCasedString: String) -> String {
        let components = snakeCasedString.split(separator: "_")
        return components.enumerated().map { (index, element) in
            index == 0 ? element.lowercased() : element.capitalized
        }.joined()
    }
}

extension Array<DiscoverItem> {
    func makeDataSourceSnapshot(region: String, itemFilter: (DiscoverItem) -> Bool) -> NSDiffableDataSourceSnapshot<Int, DiscoverItem> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverItem>()

        let section = 0
        snapshot.appendSections([section])
        let items = filter({ (itemFilter($0)) && $0.regions.contains(region) })
        snapshot.appendItems(items)

        return snapshot
    }
}

extension DiscoverItem {

    var itemType: ItemType? {
        guard let type else { return nil }
        return ItemType(snakeCasedRawValue: type)
    }

    enum ItemType: String, SnakeCaseRepresentable {
        case categories
        case podcastList
        case networkList
        case episodeList
    }

    var summaryStyleEnum: SummaryStyle? {
        guard let summaryStyle else { return nil }
        return SummaryStyle(snakeCasedRawValue: summaryStyle)
    }

    enum SummaryStyle: String, SnakeCaseRepresentable {
        case pills
        case carousel
        case smallList
        case largeList
        case singlePodcast
        case collection
        case category
        case singleEpisode
    }

    var expandedStyleEnum: ExpandedStyle? {
        guard let summaryStyle else { return nil }
        return ExpandedStyle(snakeCasedRawValue: summaryStyle)
    }

    enum ExpandedStyle: String, SnakeCaseRepresentable {
        case plainList
    }
}

class DiscoverCollectionViewController: PCViewController {
    typealias Section = Int
    typealias Item = DiscoverItem

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let coordinator: DiscoverCoordinator
    private var loadingContent = false
    private(set) var discoverLayout: DiscoverLayout?

    private var searchController: PCSearchBarController!
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
        configureDataSource()
        setupSearchBar()

        reloadData()

        addCustomObserver(Constants.Notifications.chartRegionChanged, selector: #selector(chartRegionDidChange))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AnalyticsHelper.navigatedToDiscover()
        Analytics.track(.discoverShown)

        miniPlayerStatusDidChange()
    }

    private func reloadData() {
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
//        loadingIndicator.stopAnimating()

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
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
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
            assertionFailure("Unknown Discover Item: \(type) \(summaryStyle)")
            return nil
        }
    }
}
extension DiscoverCollectionViewController {
    @objc private func chartRegionDidChange() {
        reloadData()
    }

    @objc private func checkForScrollTap(_ notification: Notification) {
        guard let index = notification.object as? Int, index == tabBarItem.tag else { return }

        let defaultOffset = -PCSearchBarController.defaultHeight - view.safeAreaInsets.top
        if collectionView.contentOffset.y.rounded(.down) > defaultOffset.rounded(.down) {
            collectionView.setContentOffset(CGPoint(x: 0, y: defaultOffset), animated: true)
        } else {
            // When double-tapping on tab bar, dismiss the search if already active
            // else give focus to the search field
            if searchController.cancelButtonShowing {
                searchController.cancelTapped(self)
            } else {
                searchController.searchTextField.becomeFirstResponder()
            }
        }
    }

    @objc private func searchRequested() {
        collectionView.setContentOffset(CGPoint(x: 0, y: -PCSearchBarController.defaultHeight - view.safeAreaInsets.top), animated: false)
        searchController.searchTextField.becomeFirstResponder()
    }
}

extension DiscoverCollectionViewController {
    func setupSearchBar() {
        searchController = PCSearchBarController()
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.didMove(toParent: self)

        let topAnchor = searchController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -PCSearchBarController.defaultHeight)
        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor
        ])
        searchController.searchControllerTopConstant = topAnchor

        searchController.setupScrollView(collectionView, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self
    }
}

extension DiscoverCollectionViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        guard let searchView = searchResultsController.view, searchView.superview == nil else {
            return
        }

        searchView.alpha = 0
        addChild(searchResultsController)
        view.addSubview(searchView)
        searchResultsController.didMove(toParent: self)


        searchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            searchView.topAnchor.constraint(equalTo: searchController.view.bottomAnchor)
        ])

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            searchView.alpha = 1
        }
    }

    func searchDidEnd() {
        guard let searchView = searchResultsController.view else { return }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            searchView.alpha = 0
        }) { _ in
            searchView.removeFromSuperview()
            self.resultsControllerDelegate.clearSearch()
        }

        Analytics.track(.searchDismissed, properties: ["source": AnalyticsSource.discover])
    }

    func searchWasCleared() {
        resultsControllerDelegate.clearSearch()
    }

    func searchTermChanged(_ searchTerm: String) {}

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        resultsControllerDelegate.performSearch(searchTerm: searchTerm, triggeredByTimer: triggeredByTimer, completion: completion)
    }
}

extension DiscoverCollectionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchResultsController.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
    }
}

extension DiscoverCollectionViewController {
    @objc func miniPlayerStatusDidChange() {
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        collectionView.contentInset = UIEdgeInsets(top: PCSearchBarController.defaultHeight, left: 0, bottom: miniPlayerOffset, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerOffset, right: 0)
    }
}

extension DiscoverCollectionViewController: UICollectionViewDelegate {

}
