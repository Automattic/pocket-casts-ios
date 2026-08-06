import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverAllViewModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var sections = [DiscoverItem]()

    let type: DiscoverServerHandler.DiscoverType

    init(type: DiscoverServerHandler.DiscoverType, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = type
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
        case failed
    }

    func load() async {
        let items: [DiscoverItem]
        do {
            items = try await discoverManager.loadDiscoverItems(type: type).filter { item in
                item.categoryID == nil
            }
        } catch {
            await MainActor.run { state = .failed }
            return
        }

        await MainActor.run {
            state = items.isEmpty ? .empty : .ready
            var finalItems = items
            switch type {
            case .signedIn:
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "single_episode", sourceType: "up_next", regions: []), at: 0)
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "small_list", sourceType: "up_next", regions: []), at: 1)
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "small_list", sourceType: "new_releases", regions: []), at: min(items.count, 4))
            case .signedOut:
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "single_episode", sourceType: "up_next", regions: []), at: 0)
                finalItems.insert(MockData.makeStubBanner(.createAccount), at: min(items.count, 3))
                finalItems.insert(DiscoverItem(type: "categories", summaryStyle: "popular_category_list", source: "https://static.pocketcasts.com/discover/json/categories_v2.json", regions: [], popular: [19, 3, 13, 18, 17, 15]), at: min(items.count, 5))
                finalItems.append(MockData.makeStubBanner(.discoverMore))
            default:
                break
            }
            self.sections = finalItems
        }
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }
}
