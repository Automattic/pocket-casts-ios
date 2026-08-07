import PocketCastsServer

enum DiscoverType: String, CaseIterable {
    case featured
    case trending
    case video = "tv_featured_videos"
    case recommendationsUser = "recommendations_user" // You might like ...
    case recommendationsSocial = "recommendations_social" // Loved By Users of ...
    case recommendationsUserPodcast = "recommendations_user_podcast" // Because you like ...
    case popularRegion = "popular_region" // Popular in region ...
    case curatedList
    case categories
    // special lists
    case twit = "twit-2026"
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

    var title: String {
        switch self {
        case .featured: L10n.discoverFeatured
        case .trending: L10n.discoverTrending
        case .video: L10n.tvHomeVideoSectionTitle
        case .recommendationsUser: L10n.youMightLike
        case .recommendationsSocial: L10n.tvHomeRecommendUserPodcastSectionTitle("...")
        case .recommendationsUserPodcast: L10n.tvHomeRecommendedForYouTitle
        case .popularRegion: L10n.discoverPopular
        case .curatedList: L10n.discoverFreshPick
        case .categories: L10n.tvHomeBrowseCategoriesSectionTitle
        case .other: L10n.discover
        default: L10n.discover
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
    let dateTime: String?
    let region: String?

    init(title: String? = nil, subtitle: String? = nil, podcasts: [DiscoverPodcast] = [], sponsoredPodcastsIDs: Set<String> = [], listId: String? = nil, dateTime: String? = nil, region: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.podcasts = podcasts
        self.sponsoredPodcastsIDs = sponsoredPodcastsIDs
        self.listId = listId
        self.dateTime = dateTime
        self.region = region
    }
}

struct DiscoverEpisodesSection {
    let title: String?
    let subtitle: String?
    let episodes: [DiscoverEpisode]
    /// Analytics list identifier for the section, used by the `discover_list_*` events.
    let listId: String?

    init(title: String? = nil, subtitle: String? = nil, episodes: [DiscoverEpisode] = [], listId: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.episodes = episodes
        self.listId = listId
    }
}

struct DiscoverCategorySection {
    let categoryDetails: DiscoverCategoryDetails
    let sponsoredPodcastsIDs: Set<String>
    let listId: String?
    let region: String?

    init(categoryDetails: DiscoverCategoryDetails, sponsoredPodcastsIDs: Set<String> = [], listId: String? = nil, region: String? = nil) {
        self.categoryDetails = categoryDetails
        self.sponsoredPodcastsIDs = sponsoredPodcastsIDs
        self.listId = listId
        self.region = region
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

    enum DiscoverError: Error {
        /// The layout or a section failed to load (network error, timeout, or bad response).
        case failedToLoad
        case failedToLoadAuthenticated
    }

    private func getLayout(type: DiscoverServerHandler.DiscoverType) async throws -> DiscoverLayout {
        let result: (DiscoverLayout?, Bool?)
        result = await discoverServerHandler.discoverPage(type: type)

        guard let layout = result.0 else {
            throw DiscoverError.failedToLoad
        }

        return layout
    }

    func loadDiscoverItems(type: DiscoverServerHandler.DiscoverType) async throws -> [DiscoverItem] {
        let discoverLayout = try await getLayout(type: type)

        return filterLayoutItemsToRegion(layout: discoverLayout)
    }

    private func filterLayoutItemsToRegion(layout: DiscoverLayout?) -> [DiscoverItem] {
        guard let discoverLayout = layout,
            let items = discoverLayout.layout else {
            return []
        }
        let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)
        let regionCode = regionCode(for: discoverLayout)

        let regionItems = items.map { item in
            guard let originalSource = item.source else {
                return item
            }
            var sourceItem = item
            let regionSource = originalSource.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)
            sourceItem.source = regionSource
            sourceItem.sourceRegion = regionCode
            return sourceItem
        }

        let filteredItems = regionItems.filter { item in
            return item.shouldShowAuthenticated() && (item.regions.isEmpty || item.regions.contains(currentRegion))
        }

        return filteredItems
    }

    func loadDiscoverSection(sourceItem: DiscoverItem) async throws -> DiscoverSection {
        guard let source = sourceItem.source else {
            return DiscoverSection(title: nil, podcasts: [], listId: sourceItem.listId(collection: nil))
        }
        guard let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: sourceItem.authenticated) else {
            throw sourceItem.authenticated == true ? DiscoverError.failedToLoadAuthenticated : DiscoverError.failedToLoad
        }
        let listId = sourceItem.listId(collection: podcastCollection)
        guard var listOfPodcasts = podcastCollection.podcasts else {
            return DiscoverSection(title: podcastCollection.title, podcasts: [], listId: listId)
        }

        let sponsoredPodcasts = await loadSponsoredPodcasts(item: sourceItem)
        for position in Array(sponsoredPodcasts.keys).sorted() {
            if let podcast = sponsoredPodcasts[position] {
                listOfPodcasts.insert(podcast, at: position)
                if let uuid = podcast.uuid {
                    sponsoredPodcastsCache[uuid] = listId
                }
            }
        }

        if sourceItem.isSponsored == true {
            for podcast in listOfPodcasts {
                if let uuid = podcast.uuid {
                    sponsoredPodcastsCache[uuid] = listId
                }
            }
        }

        for podcast in listOfPodcasts {
            if let podcastUuid = podcast.uuid {
                podcastListCache[podcastUuid] = listId
            }
        }

        return DiscoverSection(title: podcastCollection.title, subtitle: podcastCollection.subtitle, podcasts: listOfPodcasts, sponsoredPodcastsIDs: Set(sponsoredPodcasts.values.compactMap({$0.uuid})), listId: listId, dateTime: podcastCollection.datetime, region: sourceItem.sourceRegion)
    }

    func findItem(of type: DiscoverType) async throws -> DiscoverItem? {
        let items = try await loadDiscoverItems(type: .discover)
        return items.first(where: { type.match(item: $0) })
    }

    func loadDiscoverSection(type: DiscoverType) async throws -> DiscoverSection {
        guard let sourceItem = try await findItem(of: type) else {
            return DiscoverSection(title: nil, podcasts: [])
        }

        return try await loadDiscoverSection(sourceItem: sourceItem)
    }

    func loadDiscoverCategories(sourceItem: DiscoverItem, popularOnly: Bool = false) async throws -> [DiscoverCategory] {
        guard let source = sourceItem.source else {
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

    func loadDiscoverCategoryDetails(for category: DiscoverCategory) async throws -> DiscoverCategorySection? {
        let discoverLayout = try await getLayout(type: .discover)
        guard let source = category.source else {
            return nil
        }

        let regionCode = regionCode(for: discoverLayout)
        let regionSource = source.replacingOccurrences(of: discoverLayout.regionCodeToken, with: regionCode)
        guard var details = await discoverServerHandler.discoverCategoryDetails(source: regionSource, authenticated: false) else {
            throw DiscoverError.failedToLoad
        }

        var sponsoredUuids = Set<String>()
        var listId: String?
        for item in discoverLayout.layout ?? [] {
            if item.categoryID == category.id,
               item.isSponsored == true,
               let source = item.source,
               let collection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: item.authenticated == true),
               let podcasts = collection.podcasts {
                listId = item.listId(collection: collection)
                details.podcasts?.append(contentsOf: podcasts)
                sponsoredUuids = sponsoredUuids.union(Set(podcasts.compactMap({$0.uuid})))
            }
        }
        for podcastUuid in sponsoredUuids {
            sponsoredPodcastsCache[podcastUuid] = listId
        }
        if let podcasts = details.podcasts {
            for podcast in podcasts {
                if let podcastUuid = podcast.uuid {
                    podcastListCache[podcastUuid] = listId
                }
            }
        }
        return DiscoverCategorySection(categoryDetails: details, sponsoredPodcastsIDs: sponsoredUuids, listId: listId, region: regionCode)
    }

    private var sponsoredPodcastsCache: [String: String] = [:]
    private var podcastListCache: [String: String] = [:]

    func listIdForPodcast(_ uuid: String) -> String? {
        return podcastListCache[uuid]
    }

    func listIdForSponsoredPodcast(_ uuid: String) -> String? {
        return sponsoredPodcastsCache[uuid]
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
        guard let discoverLayout = try? await getLayout(type: .discover) else {
            return nil
        }
        return Settings.discoverRegion(discoverLayout: discoverLayout)
    }

    func loadDiscoverEpisodesSection(type: DiscoverType) async throws -> DiscoverEpisodesSection {
        guard let sourceItem = try await findItem(of: type) else {
            return DiscoverEpisodesSection()
        }
        return try await loadDiscoverEpisodesSection(item: sourceItem)
    }

    func loadDiscoverEpisodesSection(item: DiscoverItem) async throws -> DiscoverEpisodesSection {
        guard let source = item.source else {
            return DiscoverEpisodesSection(listId: item.listId(collection: nil))
        }
        guard let podcastCollection = await discoverServerHandler.discoverPodcastCollection(source: source, authenticated: item.authenticated) else {
            throw DiscoverError.failedToLoad
        }
        let listId = item.listId(collection: podcastCollection)
        guard let listOfEpisodes = podcastCollection.episodes else {
            return DiscoverEpisodesSection(listId: listId)
        }
        return DiscoverEpisodesSection(title: podcastCollection.title, subtitle: podcastCollection.subtitle, episodes: listOfEpisodes, listId: listId)
    }
}
