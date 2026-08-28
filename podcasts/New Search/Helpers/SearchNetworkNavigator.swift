import PocketCastsDataModel
import PocketCastsServer
import UIKit

/// Opens a network tapped in search, on the navigation stack search is presented in.
///
/// The screen it pushes is the one Discover uses for a network, ``ExpandedCollectionViewController``
/// in its `grid` style, which asks its delegate for the podcasts' subscription state and taps —
/// hence the ``DiscoverDelegate`` conformance. The Discover feed itself is out of reach from here,
/// so the methods that navigate around it do nothing.
final class SearchNetworkNavigator: ObservableObject {
    /// The view controller hosting the search results, whose navigation controller is pushed onto.
    weak var presenter: UIViewController?

    private let source: AnalyticsSource
    private let serverHandler: DiscoverServerHandling

    init(source: AnalyticsSource, serverHandler: DiscoverServerHandling = DiscoverServerHandler.shared) {
        self.source = source
        self.serverHandler = serverHandler
    }

    func show(_ network: NetworkSearchResult) {
        serverHandler.discoverPodcastCollection(source: network.source, authenticated: nil) { [weak self] collection in
            DispatchQueue.main.async {
                guard let self, let collection else { return }

                self.push(collection, for: network)
            }
        }
    }

    private func push(_ collection: PodcastCollection, for network: NetworkSearchResult) {
        guard let navigationController = presenter?.navigationController else { return }

        let controller = ExpandedCollectionViewController(item: discoverItem(for: network), podcasts: collection.podcasts ?? [])
        controller.podcastCollection = collection
        controller.registerDiscoverDelegate(self)
        navigationController.pushViewController(controller, animated: true)
    }

    /// The network's list, as the `DiscoverItem` the expanded screen expects. It opens as a `grid`,
    /// the same way a network opens from the Discover feed.
    private func discoverItem(for network: NetworkSearchResult) -> DiscoverItem {
        DiscoverItem(
            id: network.uuid,
            uuid: network.uuid,
            title: network.title,
            type: NetworkListSummary.supportedType,
            summaryStyle: "collection",
            expandedStyle: "grid",
            source: network.source,
            regions: []
        )
    }
}

extension SearchNetworkNavigator: DiscoverDelegate {
    func navController() -> UINavigationController? {
        presenter?.navigationController
    }

    func show(podcastInfo: PodcastInfo, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {
        let podcastController = PodcastViewController(podcastInfo: podcastInfo, existingImage: placeholderImage)
        podcastController.featuredPodcast = isFeatured
        podcastController.listUuid = listUuid

        navController()?.pushViewController(podcastController, animated: true)
    }

    func show(discoverPodcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {
        var podcastInfo = PodcastInfo()
        podcastInfo.populateFrom(discoverPodcast: discoverPodcast)
        show(podcastInfo: podcastInfo, placeholderImage: placeholderImage, isFeatured: isFeatured, listUuid: listUuid)
    }

    func show(podcast: Podcast) {
        navController()?.pushViewController(PodcastViewController(podcast: podcast), animated: true)
    }

    func isSubscribed(podcast: DiscoverPodcast) -> Bool {
        guard let uuid = podcast.uuid else { return false }

        return DataManager.sharedManager.findPodcast(uuid: uuid) != nil
    }

    func subscribe(podcast: DiscoverPodcast) {
        if podcast.iTunesOnly(), let iTunesId = podcast.iTunesId, let id = Int(iTunesId) {
            ServerPodcastManager.shared.subscribeFromItunesId(id, completion: nil)
        } else if let uuid = podcast.uuid {
            ServerPodcastManager.shared.subscribe(to: uuid, completion: nil)
        }

        HapticsHelper.triggerSubscribedHaptic()

        Analytics.track(.podcastSubscribed, properties: ["source": source, "uuid": podcast.uuid ?? podcast.iTunesId ?? "unknown"])
    }

    func replaceRegionCode(string: String?) -> String? { string }

    func replaceRegionName(string: String) -> String { string }

    func showExpanded(item: DiscoverItem, category: DiscoverCategory?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?, datetime: String?) {}
    func showExpanded(item: DiscoverItem, episodes: [DiscoverEpisode], podcastCollection: PodcastCollection?) {}
    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast) {}
    func failedToLoadEpisode() {}
    func invalidate(item: DiscoverItem) {}
    func navigateTo(category: String) {}
    func navigateTo(listID: String) {}
}
