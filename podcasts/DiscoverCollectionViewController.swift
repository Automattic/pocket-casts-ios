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

class DiscoverCollectionViewController: UIViewController {
    typealias Section = Int
    typealias Item = DiscoverItem

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private let coordinator: DiscoverCoordinator
    private var loadingContent = false
    private(set) var discoverLayout: DiscoverLayout?

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

        reloadData()
    }

    private func reloadData() {
//        showPageLoading()

        DiscoverServerHandler.shared.discoverPage { [weak self] discoverLayout, _ in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.populateFrom(discoverLayout: discoverLayout)
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

//    private func setupChildViewControllers() {
//        // Create and add child view controllers
//        categoryViewControllers = (0..<5).map { _ in CategoryViewController() }
//        featuredViewControllers = (0..<3).map { _ in FeaturedViewController() }
//        searchViewController = SearchViewController()
//
//        let allChildViewControllers = categoryViewControllers + featuredViewControllers + [searchViewController]
//        allChildViewControllers.forEach { addChild($0) }
//    }

    private func handleLoadFailed() {
//        loadingIndicator.stopAnimating()
//        noNetworkView.isHidden = false
    }
}

extension DiscoverCollectionViewController {
    private func setupCollectionView() {
        let layout = createCompositionalLayout(with: discoverLayout)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
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

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: viewControllerCellRegistration, for: indexPath, item: item)
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
