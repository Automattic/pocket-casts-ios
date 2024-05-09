import PocketCastsDataModel
import PocketCastsServer

protocol DiscoverSummaryProtocol: AnyObject {
    func registerDiscoverDelegate(_ delegate: DiscoverDelegate)
    func populateFrom(item: DiscoverItem)
}

protocol DiscoverDelegate: AnyObject {
    func show(podcastInfo: PodcastInfo, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?)
    func show(discoverPodcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?)
    func show(podcast: Podcast)
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?)
    func showExpanded(item: DiscoverItem, episodes: [DiscoverEpisode], podcastCollection: PodcastCollection?)
    func replaceRegionCode(string: String?) -> String?
    func replaceRegionName(string: String) -> String

    func isSubscribed(podcast: DiscoverPodcast) -> Bool
    func subscribe(podcast: DiscoverPodcast)

    func navController() -> UINavigationController?

    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast)

    func failedToLoadEpisode()
}
