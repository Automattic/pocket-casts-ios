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
            self.sections = items
        }
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }
}
