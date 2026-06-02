import PocketCastsServer

@Observable
class DiscoverSectionEpisodesModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var episodes = [DiscoverEpisode]()

    var sponsored = Set<String>()

    var title: String?

    let type: DiscoverType

    init(type: DiscoverType, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.type = type
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let episodes = MockData.makeStubVideoEpisodePodcasts()

        await MainActor.run {
            state = episodes.isEmpty ? .empty : .ready
            self.episodes = episodes
            title =  L10n.tvHomeVideoSectionTitle
        }
    }
}
