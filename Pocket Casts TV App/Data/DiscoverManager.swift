import PocketCastsServer

enum DiscoverType: String {
    case featured
    case trending
    case recommendationsUser = "recommendations_user" // You might like ...
    case recommendationsSocial = "recommendations_social" // Loved By Users of ...
    case recommendationsUserPodcast = "recommendations_user_podcast" // Because you like ...
    case popularRegion = "popular_region" // Popular in region ...

    func match(item: DiscoverItem) -> Bool {
        return item.id == self.rawValue || item.uuid == self.rawValue
    }
}
class DiscoverManager {

    static var shared: DiscoverManager = {
        return DiscoverManager()
    }()

    let discoverServerHandler: DiscoverServerHandler

    init(discoverServerHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.discoverServerHandler = discoverServerHandler
    }

    func loadDiscoverSection(type: DiscoverType) async -> [DiscoverPodcast] {
        let (result, _) = await discoverServerHandler.discoverPage()
        guard let discoverLayout = result, let items = discoverLayout.layout else {
            return []
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if type.match(item: item) {
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
