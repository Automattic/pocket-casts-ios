import Combine
import PocketCastsServer

@Observable
class DiscoverSectionModel {

    private var cancellables: Set<AnyCancellable> = []
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var podcasts = [DiscoverPodcast]()

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
        let listOfPodcasts = await discoverManager.loadDiscoverSection(type: type)

        await MainActor.run {
            state = listOfPodcasts.isEmpty ? .empty : .ready
            podcasts = listOfPodcasts
        }
    }
}

extension DiscoverPodcast: @retroactive Identifiable {

    public var id: String {
        return uuid ?? "unknown"
    }
}
