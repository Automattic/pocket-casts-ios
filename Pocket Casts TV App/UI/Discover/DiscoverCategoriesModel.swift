import PocketCastsServer

@Observable
class DiscoverCategoriesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var categories = [DiscoverCategory]()

    let popularOnly: Bool

    init(popularOnly: Bool = false, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.popularOnly = popularOnly
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let categories = await discoverManager.loadDiscoverCategories(popularOnly: popularOnly)

        await MainActor.run {
            state = categories.isEmpty ? .empty : .ready
            self.categories = categories
        }
    }
}
