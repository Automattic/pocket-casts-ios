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
    case categorySummary
    case singleEpisode
    case categoryPodcasts
    case largeListWithPodcast

    struct ItemType: Hashable {
        let cellType: DiscoverCellType
        let model: DiscoverCellModel
    }

    func viewController(in region: String) -> (UIViewController & DiscoverSummaryProtocol) {
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
            if FeatureFlag.guestListsNetworkHighlightsRedesign.enabled {
                HorizontalCollectionListViewController()
            } else {
                CollectionSummaryViewController()
            }
        case .categorySummary:
            CategorySummaryViewController(regionCode: region)
        case .singleEpisode:
            SingleEpisodeViewController()
        case .categoryPodcasts:
            CategoryPodcastsViewController(region: region)
        case .largeListWithPodcast:
            LargeListSummaryViewController()
        }
    }

    func createCellRegistration(parentViewController: UIViewController, delegate: DiscoverDelegate) -> UICollectionView.CellRegistration<UICollectionViewCell, ItemType> {
        return UICollectionView.CellRegistration<UICollectionViewCell, ItemType> { cell, _, item in

            let existingViewController = (cell.contentConfiguration as? UIViewControllerContentConfiguration)?.viewController as? (UIViewController & DiscoverSummaryProtocol)

            let vc = existingViewController ?? item.cellType.viewController(in: item.model.region)

            if existingViewController == nil {
                cell.contentConfiguration = UIViewControllerContentConfiguration(parentViewController: parentViewController, viewController: vc)
            }

            vc.registerDiscoverDelegate(delegate)
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
        case ("categories", "category", _):
            return .categorySummary
        case ("episode_list", "single_episode", _):
            return .singleEpisode
        case ("episode_list", "collection", "plain_list"):
            return .collectionSummary
        case ("category_podcast_list", _, _):
            return .categoryPodcasts
        case ("podcast_list", "large_list_with_podcast", _):
            return .largeListWithPodcast
        case ("network_list", _, _):
            FileLog.shared.addMessage("Skipping legacy network_list Discover item") // Should never be used anymore
            return nil
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
#if DEBUG
            UnknownDiscoverItemAlert.showIfNeeded(type: type, summaryStyle: summaryStyle, expandedStyle: expandedStyle)
#endif
            return nil
        }
    }
}

#if DEBUG
enum UnknownDiscoverItemAlert {
    private static let versionKey = "DebugUnknownDiscoverItemsVersion"
    private static let itemsKey = "DebugUnknownDiscoverItems"

    static func showIfNeeded(type: String?, summaryStyle: String?, expandedStyle: String?) {
        let item = "\(type ?? "unknown") / \(summaryStyle ?? "unknown") / \(expandedStyle ?? "unknown")"

        guard markAsSeenIfNeeded(item) else { return }

        let message = """
        The Discover feed returned an item this build can't render:

        type: \(type ?? "unknown")
        summaryStyle: \(summaryStyle ?? "unknown")
        expandedStyle: \(expandedStyle ?? "unknown")

        The item was skipped. This alert only appears in DEBUG builds, once per item and app version.
        """

        DispatchQueue.main.async {
            SJUIUtils.showAlert(title: "Unknown Discover Item (DEBUG)", message: message, from: SceneHelper.rootViewController())
        }
    }

    private static func markAsSeenIfNeeded(_ item: String) -> Bool {
        let defaults = UserDefaults.standard
        let version = Settings.appVersion()

        if defaults.string(forKey: versionKey) != version {
            defaults.set(version, forKey: versionKey)
            defaults.removeObject(forKey: itemsKey)
        }

        var seen = defaults.stringArray(forKey: itemsKey) ?? []
        guard !seen.contains(item) else { return false }

        seen.append(item)
        defaults.set(seen, forKey: itemsKey)
        return true
    }
}
#endif
