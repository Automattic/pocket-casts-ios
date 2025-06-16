import Foundation
import SwiftUI

import PocketCastsServer

class HorizontalCollectionModel: ObservableObject {

    @Published var colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple, .cyan, .brown, .indigo]

    @Published var item: DiscoverItem?

    @Published var podcastCollection: PodcastCollection?

    weak var discoverDelegate: DiscoverDelegate?

    var list: [[Color?]] {
        return colors.pairs()
    }

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        self.discoverDelegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {
        guard let source = item.source else { return }

        self.item = item
        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, authenticated: item.authenticated, completion: { [weak self] podcastCollection in
            self?.podcastCollection = podcastCollection
            guard podcastCollection?.podcasts != nil || podcastCollection?.episodes != nil else { return }

            DispatchQueue.main.async {
                //self?.populate()
            }
        })
    }
}

extension Color: @retroactive Identifiable {

    public var id: String {
        return description
    }
}
