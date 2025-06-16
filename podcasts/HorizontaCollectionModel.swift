import Foundation
import SwiftUI

import PocketCastsServer

class HorizontalCollectionModel: ObservableObject {

    @Published var colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple, .cyan, .brown, .indigo]

    @Published var item: DiscoverItem?

    @Published var podcastCollection: PodcastCollection?

    weak var delegate: DiscoverDelegate?

    var list: [[Color?]] {
        return colors.pairs()
    }

    var type: String {
        return podcastCollection?.subtitle ?? ""
    }

    var title: String {
        return podcastCollection?.title ?? ""
    }

    var description: String {
        return podcastCollection?.description ?? ""
    }

    var posterImage: URL? {
        guard let mobileCollage = podcastCollection?.collageImages?.filter({ $0.key == "mobile" }), let collageUrl = mobileCollage.first?.image_url else {
            return nil
        }
        return URL(string: collageUrl)
    }

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {
        guard let source = item.source else { return }

        self.item = item
        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, authenticated: item.authenticated, completion: { [weak self] podcastCollection in
            guard podcastCollection?.podcasts != nil || podcastCollection?.episodes != nil else { return }

            DispatchQueue.main.async {
                self?.podcastCollection = podcastCollection
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
}

extension Color: @retroactive Identifiable {

    public var id: String {
        return description
    }
}
