import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverHomeViewModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var sections = [DiscoverItem]()

    let signedIn: Bool

    init(signedIn: Bool, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.discoverManager = discoverManager
        self.signedIn = signedIn
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
            items = try await discoverManager.loadHomeItems(signedIn: signedIn).filter { item in
                item.categoryID == nil
            }
        } catch {
            await MainActor.run { state = .failed }
            return
        }

        await MainActor.run {
            state = items.isEmpty ? .empty : .ready
            var finalItems = items
            if signedIn {
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "single_episode", sourceType: "up_next", regions: []), at: 0)
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "small_list", sourceType: "up_next", regions: []), at: 1)
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "small_list", sourceType: "new_releases", regions: []), at: min(items.count, 4))
            } else {
                finalItems.insert(DiscoverItem(type: "episode_list", summaryStyle: "single_episode", sourceType: "up_next", regions: []), at: 0)
                finalItems.insert(MockData.makeStubBanner(.createAccount), at: min(items.count, 3))
                finalItems.append(MockData.makeStubBanner(.discoverMore))
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
