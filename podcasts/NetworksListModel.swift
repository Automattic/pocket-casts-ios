import Foundation
import PocketCastsServer

/// Backs the `lists_list` Discover row: a collection whose entries are podcast lists, one per network.
class NetworksListModel: ObservableObject {
    @Published private(set) var networks: [NetworkListSummary] = []

    private(set) var item: DiscoverItem?
    private(set) var category: DiscoverCategory?

    private weak var delegate: DiscoverDelegate?

    var title: String {
        guard let title = item?.title?.localized else { return "" }

        return delegate?.replaceRegionName(string: title) ?? title
    }

    var showsShowAll: Bool {
        item?.expandedStyle != nil
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {
        if item != self.item {
            networks = []
        }
        self.item = item
        self.category = category

        guard let source = delegate?.replaceRegionCode(string: item.source) ?? item.source else { return }

        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, authenticated: item.authenticated) { [weak self] collection in
            guard let networks = collection?.lists else { return }

            DispatchQueue.main.async {
                self?.networks = networks
            }
        }
    }

    func showAll() {
        guard let delegate, let item else { return }

        if let listId = item.uuid {
            AnalyticsHelper.listShowAllTapped(listId: listId)
        } else {
            Analytics.track(.discoverShowAllTapped, properties: ["list_id": item.inferredListId])
        }

        let gridController = NetworksGridViewController(model: self)
        gridController.title = title
        delegate.navController()?.pushViewController(gridController, animated: true)
    }

    func show(network: NetworkListSummary) {
        guard let delegate, let source = network.source else { return }

        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, authenticated: item?.authenticated) { [weak self] collection in
            guard let self, let collection else { return }

            DispatchQueue.main.async {
                delegate.showExpanded(item: self.discoverItem(for: network), podcasts: collection.podcasts ?? [], podcastCollection: collection)
            }
        }
    }

    /// The list the network points at, as the `DiscoverItem` the expanded screens expect.
    private func discoverItem(for network: NetworkListSummary) -> DiscoverItem {
        DiscoverItem(
            id: network.uuid,
            uuid: network.uuid,
            title: network.title,
            type: network.type,
            summaryStyle: network.summaryStyle,
            expandedStyle: network.expandedStyle ?? "grid",
            source: network.source,
            regions: item?.regions ?? []
        )
    }
}
