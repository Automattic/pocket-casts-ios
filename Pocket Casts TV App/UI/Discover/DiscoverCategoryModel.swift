import PocketCastsServer

@Observable
class DiscoverCategoryModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    let category: DiscoverCategory

    private var categorySection: DiscoverCategorySection?

    var coverPodcastsUuids: [String] = []

    var podcasts: [DiscoverPodcast] = []

    var sponsoredPodcastsUuids: Set<String> = []

    var source: String

    var listId: String?

    let sponsoredPosition: Int

    init(category: DiscoverCategory, source: String, discoverManager: DiscoverManager = DiscoverManager.shared, sponsoredPosition: Int = 5) {
        self.category = category
        self.source = source
        self.discoverManager = discoverManager
        self.sponsoredPosition = sponsoredPosition
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
        case failed
    }

    func load() async {
        let categorySection: DiscoverCategorySection?
        do {
            categorySection = try await discoverManager.loadDiscoverCategoryDetails(for: category)
        } catch {
            await MainActor.run { state = .failed }
            return
        }

        await MainActor.run {
            state = categorySection != nil ? .ready : .empty
            self.categorySection = categorySection
            self.podcasts = categorySection?.categoryDetails.podcasts ?? []
            self.sponsoredPodcastsUuids = categorySection?.sponsoredPodcastsIDs ?? []
            let indices = self.podcasts.indices(where: { podcast in
                self.sponsoredPodcastsUuids.contains(podcast.uuid ?? "")
            })
            let position = podcasts.count > sponsoredPosition ? sponsoredPosition : 0
            self.podcasts.moveSubranges(indices, to: position)
            if let podcasts = categorySection?.categoryDetails.podcasts {
                self.coverPodcastsUuids = podcasts.compactMap { $0.uuid }
            }
            self.listId = categorySection?.listId
        }
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }

    var icon: URL? {
        guard let urlString = category.icon, let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    var name: String {
        return category.name?.localized ?? ""
    }

    func isSponsored(podcast: DiscoverPodcast) -> Bool {
        guard let uuid = podcast.uuid else {
            return false
        }
        return sponsoredPodcastsUuids.contains(uuid)
    }

    func trackPodcastTapped(_ podcast: DiscoverPodcast) {
        guard let podcastUuid = podcast.uuid else { return }

        if let listId {
            DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, dateTime: nil, source: source)
        }

        if isSponsored(podcast: podcast) {
            DiscoverAnalytics.adTapped(categoryName: category.name, region: categorySection?.region, podcastUUID: podcastUuid, categoryID: category.id)
        }
    }
}
