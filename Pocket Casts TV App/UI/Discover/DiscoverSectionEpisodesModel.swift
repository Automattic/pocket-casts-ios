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
    }

    func load() async {
        let section: DiscoverEpisodesSection
        if let type {
            section = await discoverManager.loadDiscoverEpisodesSection(type: type)
        } else if let item {
            section = await discoverManager.loadDiscoverEpisodesSection(item: item)
        } else {
            state = .empty
            return
        }

        await MainActor.run {
            state = section.episodes.isEmpty ? .empty : .ready
            self.episodes = section.episodes
            title =  L10n.tvHomeVideoSectionTitle
            listId = section.listId
        }
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
