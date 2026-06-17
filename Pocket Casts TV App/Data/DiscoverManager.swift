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
}

struct DiscoverSection {
    let title: String?
    let subtitle: String?
    let podcasts: [DiscoverPodcast]
    let sponsoredPodcastsIDs: Set<String>
    /// Analytics list identifier for the section, used by the `discover_list_*` events.
    let listId: String?

    init(title: String? = nil, subtitle: String? = nil, podcasts: [DiscoverPodcast] = [], sponsoredPodcastsIDs: Set<String> = [], listId: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.podcasts = podcasts
        self.sponsoredPodcastsIDs = sponsoredPodcastsIDs
        self.listId = listId
    }
}

struct DiscoverEpisodesSection {
    let episodes: [DiscoverEpisode]
    /// Analytics list identifier for the section, used by the `discover_list_*` events.
    let listId: String?

    init(episodes: [DiscoverEpisode] = [], listId: String? = nil) {
        self.episodes = episodes
        self.listId = listId
    }
}

struct DiscoverCategorySection {
    let categoryDetails: DiscoverCategoryDetails
    let sponsoredPodcastsIDs: Set<String>

    init(categoryDetails: DiscoverCategoryDetails, sponsoredPodcastsIDs: Set<String> = []) {
        self.categoryDetails = categoryDetails
        self.sponsoredPodcastsIDs = sponsoredPodcastsIDs
    }
}

extension DiscoverItem {
    /// Resolves the analytics `list_id` for a section, matching the iOS scheme:
    /// the item's uuid, falling back to the collection's `list_id`, then the item's id.
    func listId(collection: PodcastCollection?) -> String? {
        uuid ?? collection?.listId ?? id
    }
}

actor DiscoverManager {

    static let shared = DiscoverManager()

    let discoverServerHandler: DiscoverServerHandler

    init(discoverServerHandler: DiscoverServerHandler = DiscoverServerHandler.shared) {
        self.discoverServerHandler = discoverServerHandler
    }

    private var cachedLayout: DiscoverLayout?
    private var layoutFetchTask: Task<(DiscoverLayout?, Bool), Never>?

    private func getLayout() async -> DiscoverLayout? {
        if let cachedLayout {
            return cachedLayout
        }

        let task = layoutFetchTask ?? Task {
            await discoverServerHandler.discoverPage()
        }
        layoutFetchTask = task
        let (result, _) = await task.value
        layoutFetchTask = nil

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

        var filteredItems = items.filter { item in
            item.shouldShowAuthenticated() && item.regions.contains(currentRegion)
        }

        let videoItem = makeVideoItem(layout: discoverLayout)
        if filteredItems.count > 2 {
            filteredItems.insert(videoItem, at: 2)
        } else {
            filteredItems.append(videoItem)
        }
        return filteredItems
    }

    func loadDiscoverSection(sourceItem: DiscoverItem) async -> DiscoverSection {
        guard  let discoverLayout = await getLayout(), let source = sourceItem.source else {
            return DiscoverSection(title: nil, podcasts: [], listId: sourceItem.listId(collection: nil))
        }
        let regionCode = regionCode(for: discoverLayout)
        let regionSource = source.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)

        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: regionSource, authenticated: sourceItem.authenticated)
        let listId = sourceItem.listId(collection: podcastCollection)
        guard var listOfPodcasts = podcastCollection?.podcasts else {
            return DiscoverSection(title: podcastCollection?.title, podcasts: [], listId: listId)
        }

        let sponsoredPodcasts = await loadSponsoredPodcasts(item: sourceItem)
        for position in Array(sponsoredPodcasts.keys).sorted() {
            if let podcast = sponsoredPodcasts[position] {
                listOfPodcasts.insert(podcast, at: position)
            }
        }

        return DiscoverSection(title: podcastCollection?.title, subtitle: podcastCollection?.subtitle, podcasts: listOfPodcasts, sponsoredPodcastsIDs: Set(sponsoredPodcasts.values.compactMap({$0.uuid})), listId: listId)
    }

    func findItem(of type: DiscoverType) async -> DiscoverItem? {
        let items = await loadDiscoverItems()
        return items.first(where: { type.match(item: $0) })
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
            let categoriesByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            popularCategories = popularIds.compactMap { categoriesByID[$0] }
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

    func loadDiscoverCategoryDetails(for category: DiscoverCategory) async -> DiscoverCategorySection? {
        guard let discoverLayout = await getLayout(),
              let source = category.source
        else {
            return nil
        }

        let regionCode = regionCode(for: discoverLayout)
        let regionSource = source.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)
        guard var details = await discoverServerHandler.discoverCategoryDetails(source: regionSource, authenticated: false) else {
            return nil
        }

        var sponsoredUuids = Set<String>()
        for item in discoverLayout.layout ?? [] {
            if item.categoryID == category.id,
               item.isSponsored == true,
               let source = item.source,
               let podcasts = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: item.authenticated == true)?.podcasts {
                details.podcasts?.append(contentsOf: podcasts)
                sponsoredUuids = sponsoredUuids.union(Set(podcasts.compactMap({$0.uuid})))
            }
        }

        return DiscoverCategorySection(categoryDetails: details, sponsoredPodcastsIDs: sponsoredUuids)
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

    func currentRegion() async -> String? {
        guard let discoverLayout = await getLayout() else {
            return nil
        }
        return Settings.discoverRegion(discoverLayout: discoverLayout)
    }

    func loadDiscoverEpisodesSection(type: DiscoverType) async -> DiscoverEpisodesSection {
        guard let sourceItem = await findItem(of: type) else {
            return DiscoverEpisodesSection()
        }
        return await loadDiscoverEpisodesSection(item: sourceItem)
    }

    func loadDiscoverEpisodesSection(item: DiscoverItem) async -> DiscoverEpisodesSection {
        guard let source = item.source else {
            return DiscoverEpisodesSection(listId: item.listId(collection: nil))
        }
        let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: item.authenticated)
        let listId = item.listId(collection: podcastCollection)
        guard let listOfEpisodes = podcastCollection?.episodes else {
            return DiscoverEpisodesSection(listId: listId)
        }

        return DiscoverEpisodesSection(episodes: listOfEpisodes, listId: listId)
    }

    func makeVideoItem(layout: DiscoverLayout) -> DiscoverItem {
        let videoItem = DiscoverItem(id: "video",
                                     uuid: "video",
                                     title: L10n.tvHomeVideoSectionTitle,
                                     type: "episode_video_list",
                                     summaryStyle: "collection",
                                     summaryItemCount: nil,
                                     expandedStyle: "plain_list",
                                     source: "https://lists.pocketcasts.com/tv_featured_videos.json",
                                     sponsoredPodcasts: nil,
                                     expandedTopItemLabel: nil,
                                     regions: Array(layout.regions?.keys.sorted() ?? []) )
        return videoItem
    }
}
