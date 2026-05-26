import PocketCastsServer

class DiscoverManager {

    static var shared: DiscoverManager = {
        return DiscoverManager()
    }()

    let discoverServerHandler: DiscoverServerHandler

    init(discoverServerHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.discoverServerHandler = discoverServerHandler
    }

    func loadDiscoverSection(id: String) async -> [DiscoverPodcast]{
        let (result, _) = await discoverServerHandler.discoverPage()
        guard let discoverLayout = result, let items = discoverLayout.layout else {
            return []
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if item.id == id {
                selectedItem = item
                break
            }
        }

        guard let sourceItem = selectedItem, let source = sourceItem.source else {
            return []
        }

        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: sourceItem.authenticated)
        guard let listOfPodcasts = podcastCollection?.podcasts else {
            return []
        }

        return listOfPodcasts
    }
}
