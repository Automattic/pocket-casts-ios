import PocketCastsServer

@Observable
class DiscoverSectionModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var podcasts = [DiscoverPodcast]()

    var sponsored = Set<String>()

    var title: String?

    var listId: String?

    var listDateTime: String?

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
            sponsored = section.sponsoredPodcastsIDs
            listId = section.listId
            listDateTime = section.listDateTime
        }
    }
}
