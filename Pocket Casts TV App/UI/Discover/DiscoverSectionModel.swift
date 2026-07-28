import PocketCastsServer

@Observable
class DiscoverSectionModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    private var section: DiscoverSection?

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
        case failed
    }

    @MainActor
    func load() async {
        let section: DiscoverSection
        do {
            if let type {
                section = try await discoverManager.loadDiscoverSection(type: type)
            } else if let item {
                section = try await discoverManager.loadDiscoverSection(sourceItem: item)
            } else {
                await MainActor.run { state = .empty }
                return
            }
        } catch {
            if let itemTitle = item?.title?.localized ?? type?.title, !itemTitle.isEmpty {
                title = itemTitle
            }
            if let discoverError = error as? DiscoverManager.DiscoverError, discoverError == .failedToLoadAuthenticated {
                state = .empty
            } else {
                state = .failed
            }
            return
        }

        self.section = section
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

    @MainActor
    func retry() async {
        state = .loading
        await load()
    }

    /// Fires once the section's podcasts are on screen, mirroring iOS's `viewDidAppear` impression.
    func trackImpression() {
        guard state == .ready, let listId else { return }
        DiscoverAnalytics.listImpression(listId: listId, source: source)
    }

    func trackPodcastTapped(_ podcast: DiscoverPodcast) {
        guard let listId, let podcastUuid = podcast.uuid else { return }
        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, dateTime: dateTime, source: source)

        if isSponsored {
            DiscoverAnalytics.adTapped(categoryName: "unknown", region: section?.region, podcastUUID: podcastUuid, categoryID: item?.categoryID)
        }
    }

    var focusStoreID: String {
        self.item?.focusStoreID ?? self.type?.rawValue ?? ""
    }
}
