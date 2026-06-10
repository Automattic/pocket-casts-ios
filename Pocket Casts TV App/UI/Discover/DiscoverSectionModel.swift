import PocketCastsServer

@Observable
class DiscoverSectionModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var podcasts = [DiscoverPodcast]()

    var sponsored = Set<String>()

    var isSponsored: Bool = false

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
        }
    }

    var focusStoreID: String {
        self.item?.focusStoreID ?? self.type?.rawValue ?? ""
    }
}
