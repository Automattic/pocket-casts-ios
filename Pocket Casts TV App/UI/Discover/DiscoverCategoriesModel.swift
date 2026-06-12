import PocketCastsServer

@Observable
class DiscoverCategoriesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var categories = [DiscoverCategory]()

    let popularOnly: Bool

    /// Analytics source ("home" or "search") used by `discover_categories_pill_tapped`.
    let source: String

    private(set) var region: String?

    init(popularOnly: Bool = false, source: String, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.popularOnly = popularOnly
        self.source = source
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let categories = await discoverManager.loadDiscoverCategories(popularOnly: popularOnly)
        let region = await discoverManager.currentRegion()

        await MainActor.run {
            state = categories.isEmpty ? .empty : .ready
            self.categories = categories
            self.region = region
        }
    }

    func trackPillTapped(_ category: DiscoverCategory) {
        DiscoverAnalytics.categoryPillTapped(category, region: region, source: source)
    }
}
