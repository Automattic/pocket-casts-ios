import PocketCastsServer

@Observable
class DiscoverSectionEpisodesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var episodes = [DiscoverEpisode]()

    var sponsored = Set<String>()

    var title: String = ""

    let type: DiscoverType?

    let item: DiscoverItem?

    /// Analytics source ("home" or "search") used by the `discover_list_*` events.
    let source: String

    private(set) var listId: String?

    init(type: DiscoverType, source: String, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = type
        self.item = nil
        self.source = source
        self.discoverManager = discoverManager
    }

    init(item: DiscoverItem, source: String, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = nil
        self.item = item
        self.source = source
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
        case failed
    }

    @MainActor
    func load() async {
        let section: DiscoverEpisodesSection
        do {
            if let type {
                section = try await discoverManager.loadDiscoverEpisodesSection(type: type)
            } else if let item {
                section = try await discoverManager.loadDiscoverEpisodesSection(item: item)
            } else {
                state = .empty
                return
            }
        } catch {
            if let itemTitle = item?.title?.localized ?? type?.title, !itemTitle.isEmpty {
                title = itemTitle
            }
            state = .failed
            return
        }

        state = section.episodes.isEmpty ? .empty : .ready
        self.episodes = section.episodes
        var composedTitle = section.title?.localized ?? ""
        if let subtitle = section.subtitle?.localized, !subtitle.isEmpty {
            composedTitle = subtitle + ": " + composedTitle
        }
        title = composedTitle
        listId = section.listId
    }

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }

    /// Fires once the section's episodes are on screen, mirroring iOS's `viewDidAppear` impression.
    func trackImpression() {
        guard state == .ready, let listId else { return }
        DiscoverAnalytics.listImpression(listId: listId, source: source)
    }

    var focusStoreID: String {
        self.item?.focusStoreID ?? self.type?.rawValue ?? ""
    }
}
