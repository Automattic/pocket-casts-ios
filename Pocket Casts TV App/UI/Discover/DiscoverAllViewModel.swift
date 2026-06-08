import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverAllViewModel {
    private let discoverManager: DiscoverManager

    var state: State = .loading

    var sections = [DiscoverItem]()

    init(discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.discoverManager = discoverManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    func load() async {
        let items = await discoverManager.loadDiscoverItems().filter { item in
            item.categoryID == nil
        }

        await MainActor.run {
            state = items.isEmpty ? .empty : .ready
            self.sections = items
        }
    }
}

enum DiscoverRowType: CaseIterable {
    case categories
    case featured
    case listPodcast
    case singlePodcast
    case listEpisode
    case singleEpisode
}

extension DiscoverItem {
    var rowType: DiscoverRowType? {
        switch (type, summaryStyle, expandedStyle) {
        case ("categories", "pills", _):
            return .categories
        case ("podcast_list", "carousel", _):
            return .featured
        case ("podcast_list", "small_list", _):
            return .listPodcast
        case ("podcast_list", "large_list", _):
            return .listPodcast
        case ("podcast_list", "single_podcast", _):
            return .singlePodcast
        case ("podcast_list", "collection", _):
            return .listPodcast
        case ("network_list", _, _):
            return .listPodcast
        case ("categories", "category", _):
            return .categories
        case ("episode_list", "single_episode", _):
            return .singleEpisode
        case ("episode_list", "collection", "plain_list"):
            return .listEpisode
        case ("category_podcast_list", _, _):
            return .categories
        case ("podcast_list", "large_list_with_podcast", _):
            return .listPodcast
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            assertionFailure("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            return nil
        }
    }
}
