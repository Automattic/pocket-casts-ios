import PocketCastsServer

@Observable
class DiscoverSectionEpisodesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var episodes = [DiscoverEpisode]()

    var sponsored = Set<String>()

    var title: String?

    let type: DiscoverType?

    let item: DiscoverItem?

    init(type: DiscoverType, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = type
        self.item = nil
        self.discoverManager = discoverManager
    }

    init(item: DiscoverItem, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = nil
        self.item = item
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let episodes: [DiscoverEpisode]
        if let type {
            episodes = await discoverManager.loadDiscoverEpisodesSection(type: type)
        } else if let item {
            episodes = await discoverManager.loadDiscoverEpisodesSection(item: item)
        } else {
            state = .empty
            return
        }

        await MainActor.run {
            state = episodes.isEmpty ? .empty : .ready
            self.episodes = episodes
            title =  L10n.tvHomeVideoSectionTitle
        }
    }
}
