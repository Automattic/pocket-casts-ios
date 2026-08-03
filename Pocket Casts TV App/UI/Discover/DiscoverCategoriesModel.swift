import PocketCastsServer

@Observable
class DiscoverCategoriesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var categories = [DiscoverCategory]()

    let item: DiscoverItem
    let popularOnly: Bool

    /// Analytics source ("home" or "search") used by `discover_categories_pill_tapped`.
    let source: String

    private(set) var region: String?

    init(item: DiscoverItem, popularOnly: Bool = false, source: String, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.item = item
        self.popularOnly = popularOnly
        self.source = source
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
        case failed
    }

    func load() async {
        let categories: [DiscoverCategory]
        do {
            categories = try await discoverManager.loadDiscoverCategories(sourceItem: item, popularOnly: popularOnly)
        } catch {
            await MainActor.run { state = .failed }
            return
        }
        let region = await discoverManager.currentRegion()

        await MainActor.run {
            state = categories.isEmpty ? .empty : .ready
            self.categories = categories
            self.region = region
        }
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }

    func trackPillTapped(_ category: DiscoverCategory) {
        DiscoverAnalytics.categoryPillTapped(category, region: region, source: source)
    }
}
