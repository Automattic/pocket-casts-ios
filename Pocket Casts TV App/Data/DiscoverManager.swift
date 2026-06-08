import PocketCastsServer

enum DiscoverType: String, CaseIterable {
    case featured
    case trending
    case video
    case recommendationsUser = "recommendations_user" // You might like ...
    case recommendationsSocial = "recommendations_social" // Loved By Users of ...
    case recommendationsUserPodcast = "recommendations_user_podcast" // Because you like ...
    case popularRegion = "popular_region" // Popular in region ...
    case curatedList
    case categories
    case other

    func match(item: DiscoverItem) -> Bool {
        switch self {
        case .featured:
            return item.id == self.rawValue || item.uuid == self.rawValue
        case .curatedList:
            return item.curated == true && item.type == "podcast_list" && item.summaryStyle == "large_list"
        case .categories:
            return item.type == "categories"
        default:
            return item.id == self.rawValue || item.uuid == self.rawValue
        }
    }

    static func itemType(for item: DiscoverItem) -> DiscoverType? {
        for type in DiscoverType.allCases {
            if type.match(item: item) {
                return type
            }
        }
        return .other
    }
}

enum DiscoverListType: String {

    case podcastList = "podcast_list"
}

struct DiscoverSection {
    let title: String?
    let subtitle: String?
    let podcasts: [DiscoverPodcast]
    let sponsoredPodcastsIDs: Set<String>

    init(title: String? = nil, subtitle: String? = nil, podcasts: [DiscoverPodcast] = [], sponsoredPodcastsIDs: Set<String> = []) {
        self.title = title
        self.subtitle = subtitle
        self.podcasts = podcasts
        self.sponsoredPodcastsIDs = sponsoredPodcastsIDs
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

    func loadDiscoverItems() async -> [DiscoverItem] {
        guard let discoverLayout = await getLayout(), let items = discoverLayout.layout else {
            return []
        }
        let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)

        let filteredItems = items.filter { item in
            item.shouldShowAuthenticated() && item.regions.contains(currentRegion)
        }

        return filteredItems
    }

    func loadDiscoverSection(sourceItem: DiscoverItem) async -> DiscoverSection {
        guard  let discoverLayout = await getLayout(), let source = sourceItem.source else {
            return DiscoverSection(title: nil, podcasts: [])
        }
        let regionCode = regionCode(for: discoverLayout)
        let regionSource = source.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)

        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: regionSource, authenticated: sourceItem.authenticated)
        guard var listOfPodcasts = podcastCollection?.podcasts else {
            return DiscoverSection(title: podcastCollection?.title, podcasts: [])
        }

        let sponsoredPodcasts = await loadSponsoredPodcasts(item: sourceItem)
        for position in Array(sponsoredPodcasts.keys).sorted() {
            if let podcast = sponsoredPodcasts[position] {
                listOfPodcasts.insert(podcast, at: position)
            }
        }

        return DiscoverSection(title: podcastCollection?.title, subtitle: podcastCollection?.subtitle, podcasts: listOfPodcasts, sponsoredPodcastsIDs: Set(sponsoredPodcasts.values.compactMap({$0.uuid})))
    }

    func findItem(of type: DiscoverType) async -> DiscoverItem? {
        guard let discoverLayout = await getLayout(), let items = discoverLayout.layout else {
            return nil
        }
        var selectedItem: DiscoverItem?
        for item in items {
            if type.match(item: item) {
                selectedItem = item
                break
            }
        }
        return selectedItem
    }

    func loadDiscoverSection(type: DiscoverType) async -> DiscoverSection {
        guard let sourceItem = await findItem(of: type) else {
            return DiscoverSection(title: nil, podcasts: [])
        }

        return await loadDiscoverSection(sourceItem: sourceItem)
    }

    func loadDiscoverCategories(popularOnly: Bool = false) async -> [DiscoverCategory] {
        guard let sourceItem = await findItem(of: .categories), let source = sourceItem.source else {
            return []
        }

        let categories = await discoverServerHandler.discoverCategories(source: source, authenticated: sourceItem.authenticated)

        guard popularOnly else {
            return categories
        }

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

    func loadDiscoverVideoSection() async -> [DiscoverEpisode] {
        let videoSource = "https://lists.pocketcasts.com/tv_featured_videos.json"
        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: videoSource, authenticated: false)
        guard let listOfEpisodes = podcastCollection?.episodes else {
            return []
        }

        return listOfEpisodes
    }
}
