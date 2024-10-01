import PocketCastsServer
import PocketCastsUtils

struct DiscoverCellModel: Hashable {
    let item: DiscoverItem
    let region: String
    let selectedCategory: DiscoverCategory?
}

enum DiscoverCellType: CaseIterable {
    case categoriesSelector
    case featuredSummary
    case smallPagedListSummary
    case largeListSummary
    case singlePodcast
    case collectionSummary
    case networkSummary
    case categorySummary
    case singleEpisode
    case categoryPodcasts

    typealias ItemType = DiscoverCellModel

    func viewController(in region: String, for category: DiscoverCategory?) -> (UIViewController & DiscoverSummaryProtocol) {
        switch self {
        case .categoriesSelector:
            CategoriesSelectorViewController()
        case .featuredSummary:
            FeaturedSummaryViewController()
        case .smallPagedListSummary:
            SmallPagedListSummaryViewController()
        case .largeListSummary:
            LargeListSummaryViewController()
        case .singlePodcast:
            SinglePodcastViewController()
        case .collectionSummary:
            CollectionSummaryViewController()
        case .networkSummary:
            NetworkSummaryViewController()
        case .categorySummary:
            CategorySummaryViewController(regionCode: region)
        case .singleEpisode:
            SingleEpisodeViewController()
        case .categoryPodcasts:
            CategoryPodcastsViewController(category: category!, region: region)
        }
    }

    func createCellRegistration(delegate: DiscoverDelegate) -> UICollectionView.CellRegistration<UICollectionViewCell, ItemType> {
        return UICollectionView.CellRegistration<UICollectionViewCell, ItemType> { cell, indexPath, item in

            let existingViewController = (cell.contentConfiguration as? UIViewControllerContentConfiguration)?.viewController as? (UIViewController & DiscoverSummaryProtocol)

            let vc = existingViewController ?? viewController(in: item.region, for: item.selectedCategory)

            if existingViewController == nil {
                cell.contentConfiguration = UIViewControllerContentConfiguration(viewController: vc)
            }

            vc.registerDiscoverDelegate(delegate)
            vc.populateFrom(item: item.item, region: item.region, category: item.selectedCategory)
        }
    }
}

extension DiscoverItem {
    func cellType() -> DiscoverCellType? {
        switch (type, summaryStyle, expandedStyle) {
        case ("categories", "pills", _):
            return .categoriesSelector
        case ("podcast_list", "carousel", _):
            return .featuredSummary
        case ("podcast_list", "small_list", _):
            return .smallPagedListSummary
        case ("podcast_list", "large_list", _):
            return .largeListSummary
        case ("podcast_list", "single_podcast", _):
            return .singlePodcast
        case ("podcast_list", "collection", _):
            return .collectionSummary
        case ("network_list", _, _):
            return .networkSummary
        case ("categories", "category", _):
            return .categorySummary
        case ("episode_list", "single_episode", _):
            return .singleEpisode
        case ("episode_list", "collection", "plain_list"):
            return .collectionSummary
        case ("category_podcast_list", _, _):
            return .categoryPodcasts
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            assertionFailure("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            return nil
        }
    }
}
