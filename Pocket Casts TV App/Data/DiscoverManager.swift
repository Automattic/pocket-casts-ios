import PocketCastsServer

enum DiscoverType: String {
    case featured
    case trending
    case video
    case recommendationsUser = "recommendations_user" // You might like ...
    case recommendationsSocial = "recommendations_social" // Loved By Users of ...
    case recommendationsUserPodcast = "recommendations_user_podcast" // Because you like ...
    case popularRegion = "popular_region" // Popular in region ...
    case curatedList
    case categories

    func match(item: DiscoverItem) -> Bool {
        switch self {
        case .curatedList:
            return item.curated == true && item.type == "podcast_list" && item.summaryStyle == "large_list"
        default:
            return item.id == self.rawValue || item.uuid == self.rawValue
        }
    }
}

struct DiscoverSection {
    let title: String?
    let podcasts: [DiscoverPodcast]
    let sponsoredPodcasts: Set<String>

    init(title: String? = nil, podcasts: [DiscoverPodcast] = [], sponsoredPodcasts: Set<String> = []) {
        self.title = title
        self.podcasts = podcasts
        self.sponsoredPodcasts = sponsoredPodcasts
    }
}

actor DiscoverManager {

    static let shared = DiscoverManager()

    let discoverServerHandler: DiscoverServerHandler

    init(discoverServerHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.discoverServerHandler = discoverServerHandler
    }

    private var cachedLayout: DiscoverLayout?

    private func getLayout() async -> DiscoverLayout? {
        if cachedLayout != nil {
            return cachedLayout
        }

        let (result, _) = await discoverServerHandler.discoverPage()
        guard let layout = result else {
            return nil
        }
        cachedLayout = layout
        return layout
    }

    func loadDiscoverSection(type: DiscoverType) async -> DiscoverSection {
        guard let discoverLayout = await getLayout(), let items = discoverLayout.layout else {
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
        guard var listOfPodcasts = podcastCollection?.podcasts else {
            return DiscoverSection(title: podcastCollection?.title, podcasts: [])
        }

        let sponsoredPodcasts = await loadSponsoredPodcasts(item: sourceItem)
        for position in Array(sponsoredPodcasts.keys).sorted() {
            if let podcast = sponsoredPodcasts[position] {
                listOfPodcasts.insert(podcast, at: position)
            }
        }

        return DiscoverSection(title: podcastCollection?.title, podcasts: listOfPodcasts, sponsoredPodcasts: Set(sponsoredPodcasts.values.compactMap({$0.uuid})))
    }

    func loadDiscoverCategories() async -> [DiscoverCategory] {
        guard let discoverLayout = await getLayout(), let items = discoverLayout.layout else {
            return []
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if item.type == "categories" {
                selectedItem = item
                break
            }
        }

        guard let sourceItem = selectedItem, let source = sourceItem.source else {
            return []
        }

        let categories = await discoverServerHandler.discoverCategories(source: source, authenticated: sourceItem.authenticated)

        return categories
    }

    func loadDiscoverPopularCategories() async -> [DiscoverCategory] {
        guard let discoverLayout = await getLayout(), let items = discoverLayout.layout else {
            return []
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if item.type == "categories" {
                selectedItem = item
                break
            }
        }

        guard let sourceItem = selectedItem, let source = sourceItem.source else {
            return []
        }

        let categories = await discoverServerHandler.discoverCategories(source: source, authenticated: sourceItem.authenticated)
        var popularCategories: [DiscoverCategory] = []

        if let popularIds = sourceItem.popular {
            for popularId in popularIds {
                if let category = categories.first(where: { $0.id == popularId } ) {
                    popularCategories.append(category)
                }
            }
        }
        if popularCategories.isEmpty {
            popularCategories = categories
        }
        return popularCategories
    }

    private func regionCode(for layout: DiscoverLayout) -> String {
        let currentRegionCode = Settings.discoverRegion(discoverLayout: layout)
        let serverRegion = layout.regions?[currentRegionCode]?.code ?? "us"
        return serverRegion
    }

    func loadDiscoverCategoryDetails(for category: DiscoverCategory) async -> DiscoverCategoryDetails? {
        guard let discoverLayout = await getLayout(),
              let source = category.source
        else {
            return nil
        }

        let regionCode = regionCode(for: discoverLayout)
        let regionSource = source.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)
        let details = await discoverServerHandler.discoverCategoryDetails(source: regionSource, authenticated: false)
        return details
    }

    func loadSponsoredPodcasts(item: DiscoverItem) async -> [Int: DiscoverPodcast] {
        var resultPodcasts = [Int: DiscoverPodcast]()
        guard let sponsoredPodcasts = item.sponsoredPodcasts else {
            return [:]
        }
        for sponsored in sponsoredPodcasts {
            guard let source = sponsored.source, let position = sponsored.position else {
                continue
            }
            let podcastList = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: item.authenticated)
            guard let podcastList, let discoverPodcast = podcastList.podcasts?.first else { continue }
            resultPodcasts[position] = discoverPodcast
        }
        return resultPodcasts
    }
}
