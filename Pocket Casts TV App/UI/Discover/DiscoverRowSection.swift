import SwiftUI
import PocketCastsServer
import PocketCastsUtils

enum DiscoverRowType: CaseIterable {
    case categories
    case featured
    case listPodcast
    case singlePodcast
    case listEpisode
    case singleEpisode
    case listVideoEpisode
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
        case ("episode_list", "video_preview_list", "plain_list"):
            return .listVideoEpisode
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

struct DiscoverRowSection: View {

    var item: DiscoverItem
    let source: String

    init(item: DiscoverItem, source: String) {
        self.item = item
        self.source = source
    }

    var body: some View {
        ZStack {
            switch item.rowType {
            case .categories:
                DiscoverCategoriesRow(item: item, popularOnly: false, source: source)
            case .featured:
                DiscoverFeaturedPodcastsRow(item: item, source: source)
            case .listVideoEpisode:
                DiscoverVideoEpisodesRow(item: item, source: source)
            case .singlePodcast:
                DiscoverSinglePodcastRow(item: item, source: source)
            case .listEpisode:
                DiscoverEpisodesRow(item: item, source: source)
            case .singleEpisode:
                DiscoverEpisodesRow(item: item, source: source)
            default:
                DiscoverPodcastRow(item: item, source: source)
            }
        }
    }
}
