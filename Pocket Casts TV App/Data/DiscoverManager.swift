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

struct DiscoverSection {
    let title: String?
    let podcasts: [DiscoverPodcast]
}

class DiscoverManager {

    static let shared = DiscoverManager()

    let discoverServerHandler: DiscoverServerHandler

    init(discoverServerHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.discoverServerHandler = discoverServerHandler
    }

    func loadDiscoverSection(type: DiscoverType) async -> DiscoverSection {
        let (result, _) = await discoverServerHandler.discoverPage()
        guard let discoverLayout = result, let items = discoverLayout.layout else {
            return DiscoverSection(title: nil, podcasts: [])
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if type.match(item: item) {
                selectedItem = item
                break
            }
        }

        guard let sourceItem = selectedItem, let source = sourceItem.source else {
            return DiscoverSection(title: nil, podcasts: [])
        }

        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: sourceItem.authenticated)
        guard let listOfPodcasts = podcastCollection?.podcasts else {
            return DiscoverSection(title: podcastCollection?.title, podcasts: [])
        }

        return DiscoverSection(title: podcastCollection?.title, podcasts: listOfPodcasts)
    }
}
