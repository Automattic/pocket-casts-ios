import PocketCastsServer

@Observable
class DiscoverSectionModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var podcasts = [DiscoverPodcast]()

    var sponsored = Set<String>()

    var isSponsored: Bool = false

    var title: String = ""

    let type: DiscoverType?

    let item: DiscoverItem?

    /// Analytics source ("home" or "search") used by the `discover_list_*` events.
    let source: String

    private(set) var listId: String?

    private(set) var dateTime: String?

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
        let section: DiscoverSection
        if let type {
            section = await discoverManager.loadDiscoverSection(type: type)
        } else if let item {
            section = await discoverManager.loadDiscoverSection(sourceItem: item)
        } else {
            state = .empty
            return
        }

        await MainActor.run {
            state = section.podcasts.isEmpty ? .empty : .ready
            podcasts = section.podcasts
            var composedTitle = section.title?.localized ?? ""
            if let subtitle = section.subtitle?.localized, !subtitle.isEmpty {
                composedTitle = subtitle + ": " + composedTitle
            }
            title = composedTitle
            sponsored = section.sponsoredPodcastsIDs
            isSponsored = item?.isSponsored ?? false
            listId = section.listId
            dateTime = section.dateTime
        }
    }

    /// Fires once the section's podcasts are on screen, mirroring iOS's `viewDidAppear` impression.
    func trackImpression() {
        guard state == .ready, let listId else { return }
        DiscoverAnalytics.listImpression(listId: listId, source: source)
    }

    func trackPodcastTapped(_ podcast: DiscoverPodcast) {
        guard let listId, let podcastUuid = podcast.uuid else { return }
        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, dateTime: dateTime, source: source)
    }

    var focusStoreID: String {
        self.item?.focusStoreID ?? self.type?.rawValue ?? ""
    }
}
