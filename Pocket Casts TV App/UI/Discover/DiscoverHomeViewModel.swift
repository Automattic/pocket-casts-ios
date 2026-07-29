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
            self.sections = items
        }
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }
}
