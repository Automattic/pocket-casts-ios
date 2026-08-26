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

        var sections = [DiscoverItem]()
        var unrenderedItems = [DiscoverItem]()
        for item in items {
            if item.rowType != nil {
                sections.append(item)
            } else {
                unrenderedItems.append(item)
            }
        }
        reportUnknownItems(unrenderedItems)

        await MainActor.run {
            state = sections.isEmpty ? .empty : .ready
            self.sections = sections
        }
    }

    private func reportUnknownItems(_ items: [DiscoverItem]) {
        #if DEBUG || STAGING
            guard let unknown = items.first else { return }

            ToastManager.shared.show("UNKNOWN DISCOVER ITEM: \(unknown.type ?? "unknown"), CHECK CONSOLE!")
        #endif
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }
}
