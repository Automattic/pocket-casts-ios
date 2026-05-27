import PocketCastsServer

@Observable
class DiscoverCategoriesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var categories = [DiscoverCategory]()

    init(discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let categories = await discoverManager.loadDiscoverCategories()

        await MainActor.run {
            state = categories.isEmpty ? .empty : .ready
            self.categories = categories
        }
    }
}
