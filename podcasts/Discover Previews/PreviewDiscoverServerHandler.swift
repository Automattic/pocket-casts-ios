#if DEBUG

import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import UIKit

/// A ``DiscoverServerHandling`` that answers from ``DiscoverPreviewData`` instead of the network.
///
/// A section only fetches the one kind of payload it renders, so a preview supplies just that. The
/// featured carousel is the exception: it loads each sponsored slot from its own URL, which
/// `collectionsBySource` covers.
final class PreviewDiscoverServerHandler: DiscoverServerHandling {
    var podcastList: PodcastList?
    var podcastCollection: PodcastCollection?
    var categories: [DiscoverCategory]
    var categoryDetails: DiscoverCategoryDetails?
    var collectionsBySource: [String: PodcastCollection]

    init(
        podcastList: PodcastList? = nil,
        podcastCollection: PodcastCollection? = nil,
        categories: [DiscoverCategory] = [],
        categoryDetails: DiscoverCategoryDetails? = nil,
        collectionsBySource: [String: PodcastCollection] = [:]
    ) {
        self.podcastList = podcastList
        self.podcastCollection = podcastCollection
        self.categories = categories
        self.categoryDetails = categoryDetails
        self.collectionsBySource = collectionsBySource
    }

    func discoverPodcastList(source: String, authenticated: Bool?, completion: @escaping (PodcastList?) -> Void) {
        completion(podcastList)
    }

    func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        completion(collection(for: source))
    }

    func discoverCategories(source: String, authenticated: Bool?, completion: @escaping ([DiscoverCategory]?) -> Void) {
        completion(categories)
    }

    func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
        categories
    }

    func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        completion(categoryDetails)
    }

    func discoverItem<T>(_ source: String?, authenticated: Bool, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        let response: Any = collection(for: source ?? "") as Any
        guard let value = response as? T else {
            return Empty().eraseToAnyPublisher()
        }
        return Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    private func collection(for source: String) -> PodcastCollection? {
        collectionsBySource[source] ?? podcastCollection
    }
}

/// A ``DiscoverDelegate`` that records taps rather than navigating anywhere.
///
/// Sections ask it for subscription state and region substitutions while laying out, so those are
/// the only methods that return anything meaningful.
final class PreviewDiscoverDelegate: DiscoverDelegate {
    /// Podcasts to draw with the followed tick, by index into ``DiscoverPreviewData/podcasts(_:)``.
    var subscribedUUIDs: Set<String>

    /// Stands in for the region the server's `[regionname]` token is replaced with.
    var regionName: String

    init(subscribedUUIDs: Set<String> = [], regionName: String = "United States") {
        self.subscribedUUIDs = subscribedUUIDs
        self.regionName = regionName
    }

    func isSubscribed(podcast: DiscoverPodcast) -> Bool {
        guard let uuid = podcast.uuid else { return false }
        return subscribedUUIDs.contains(uuid)
    }

    func subscribe(podcast: DiscoverPodcast) {
        guard let uuid = podcast.uuid else { return }
        subscribedUUIDs.insert(uuid)
    }

    func replaceRegionCode(string: String?) -> String? {
        string?.replacingOccurrences(of: "[regioncode]", with: "us")
    }

    func replaceRegionName(string: String) -> String {
        string.localized(with: regionName) ?? string.replacingOccurrences(of: "[regionname]", with: regionName)
    }

    func navController() -> UINavigationController? { nil }

    func show(podcastInfo: PodcastInfo, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {}
    func show(discoverPodcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {}
    func show(podcast: Podcast) {}
    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast) {}
    func showExpanded(item: DiscoverItem, category: DiscoverCategory?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?, datetime: String?) {}
    func showExpanded(item: DiscoverItem, episodes: [DiscoverEpisode], podcastCollection: PodcastCollection?) {}
    func failedToLoadEpisode() {}
    func invalidate(item: DiscoverItem) {}
    func navigateTo(category: String) {}
    func navigateTo(listID: String) {}
}

#endif
