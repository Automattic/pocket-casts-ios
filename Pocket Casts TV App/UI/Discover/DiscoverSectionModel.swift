import Combine
import PocketCastsServer

@Observable
class DiscoverSectionModel {

    private var cancellables: Set<AnyCancellable> = []
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var podcasts = [DiscoverPodcast]()

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
        let section = await discoverManager.loadDiscoverSection(type: type)

        await MainActor.run {
            state = section.podcasts.isEmpty ? .empty : .ready
            podcasts = section.podcasts
            title = section.title
        }
    }
}

extension DiscoverPodcast: @retroactive Identifiable {

    public var id: String {
        return uuid ?? "unknown"
    }
}
