import PocketCastsDataModel
import PocketCastsServer
import UIKit

/// Opens a network, on the navigation stack of the screen that asked for it.
///
/// A network is a list of podcasts, identified by the id the API gives it, and the screen it opens
/// is the one Discover uses, ``ExpandedCollectionViewController`` in its `grid` style. That screen
/// asks its delegate for the podcasts' subscription state and taps — hence the ``DiscoverDelegate``
/// conformance. Callers see none of that: they hand over a list id and this loads the rest.
final class NetworkNavigator: ObservableObject {
    /// The view controller whose navigation controller is pushed onto.
    weak var presenter: UIViewController?

    private let source: AnalyticsSource
    private let serverHandler: DiscoverServerHandling

    private var pendingListId: String?

    init(source: AnalyticsSource, serverHandler: DiscoverServerHandling = DiscoverServerHandler.shared) {
        self.source = source
        self.serverHandler = serverHandler
    }

    /// Loads the network's podcasts and shows them. `title` names the screen for callers that
    /// already know it; the list names itself otherwise.
    func show(listId: String, title: String? = nil) {
        guard pendingListId != listId else { return }

        pendingListId = listId
        serverHandler.discoverPodcastCollection(source: ServerHelper.listUrlString(listId: listId), authenticated: nil) { [weak self] collection in
            DispatchQueue.main.async {
                guard let self, self.pendingListId == listId else { return }

                self.pendingListId = nil
                self.show(collection, listId: listId, title: title)
            }
        }
    }

    private func show(_ collection: PodcastCollection?, listId: String, title: String?) {
        guard let presenter, presenter.viewIfLoaded?.window != nil, let navigationController = presenter.navigationController else { return }

        guard let collection else {
            Toast.show(L10n.networkFailToLoad)
            return
        }

        let item = discoverItem(listId: listId, title: title ?? collection.title)
        let controller = ExpandedCollectionViewController(item: item, podcasts: collection.podcasts ?? [])
        controller.podcastCollection = collection
        controller.registerDiscoverDelegate(self)
        navigationController.pushViewController(controller, animated: true)
    }

    /// The network's list, as the `DiscoverItem` the expanded screen expects. It opens as a `grid`,
    /// the same way a network opens from the Discover feed.
    private func discoverItem(listId: String, title: String?) -> DiscoverItem {
        DiscoverItem(
            id: listId,
            uuid: listId,
            title: title,
            type: NetworkListSummary.supportedType,
            summaryStyle: "collection",
            expandedStyle: "grid",
            source: ServerHelper.listUrlString(listId: listId),
            regions: []
        )
    }
}

extension NetworkNavigator: DiscoverDelegate {
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
