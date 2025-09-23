import Foundation
import SwiftUI

import PocketCastsServer

extension DiscoverPodcast: @retroactive Identifiable {
    public var id: String {
        return self.uuid ?? UUID().uuidString
    }
}

class HorizontalCollectionModel: ObservableObject {

    var category: DiscoverCategory?

    @Published var item: DiscoverItem?

    @Published var podcastCollection: PodcastCollection?

    weak var delegate: DiscoverDelegate?

    @Published var list: [[DiscoverPodcast]] = []

    var type: String {
        return podcastCollection?.subtitle ?? ""
    }

    var title: String {
        return podcastCollection?.title ?? ""
    }

    var description: String {
        return podcastCollection?.shortDescription ?? podcastCollection?.description ?? ""
    }

    var posterImage: URL? {
        guard let posterURL = podcastCollection?.collectionRectangleImage ?? podcastCollection?.collectionImage else {
            return nil
        }
        return URL(string: posterURL)
    }

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {
        guard let source = item.source else { return }

        self.item = item
        self.category = category
        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, authenticated: item.authenticated, completion: { [weak self] podcastCollection in
            guard podcastCollection?.podcasts != nil || podcastCollection?.episodes != nil else { return }

            DispatchQueue.main.async {
                self?.podcastCollection = podcastCollection
                guard let podcastCollection, let podcasts = podcastCollection.podcasts else {
                    self?.list = []
                    return
                }

                self?.list = podcasts.pairs()
            }
        })
    }

    func showCollection() {
        guard let delegate = delegate, let item = item else { return }

        if let podcasts = podcastCollection?.podcasts, !podcasts.isEmpty {
            delegate.showExpanded(item: item, podcasts: podcasts, podcastCollection: podcastCollection)
        } else if let episodes = podcastCollection?.episodes, !episodes.isEmpty {
            delegate.showExpanded(item: item, episodes: episodes, podcastCollection: podcastCollection)
        }
    }

    func showPodcast(_ podcast: DiscoverPodcast) {
        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: item?.uuid)
    }

    func subscribePodcast(_ podcast: DiscoverPodcast) {
        if let listId = item?.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
        }
        delegate?.subscribe(podcast: podcast)
    }
}
