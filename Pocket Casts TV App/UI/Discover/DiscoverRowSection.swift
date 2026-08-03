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
    case banner
    case upNext
    case nowPlaying
    case newReleases
}

extension DiscoverItem {
    var rowType: DiscoverRowType? {
        switch (type, summaryStyle, expandedStyle, sourceType) {
        case ("categories", "pills", _, _):
            return .categories
        case ("podcast_list", "carousel", _, _):
            return .featured
        case ("podcast_list", "small_list", _, _):
            return .listPodcast
        case ("podcast_list", "large_list", _, _):
            return .listPodcast
        case ("podcast_list", "single_podcast", _, _):
            return .singlePodcast
        case ("podcast_list", "collection", _, _):
            return .listPodcast
        case ("network_list", _, _, _):
            return .listPodcast
        case ("categories", "category", _, _):
            return .categories
        case ("episode_list", "single_episode", _, nil):
            return .singleEpisode
        case ("episode_list", "collection", "plain_list", nil):
            return .listEpisode
        case ("episode_list", "video_preview_list", "plain_list", _):
            return .listVideoEpisode
        case ("category_podcast_list", _, _, _):
            return .categories
        case ("podcast_list", "large_list_with_podcast", _, _):
            return .listPodcast
        case ("episode_list", "single_episode", _, "up_next"):
            return .nowPlaying
        case ("episode_list", "small_list", _, "up_next"):
            return .upNext
        case ("episode_list", "small_list", _, "new_releases"):
            return .newReleases
        case ("banner", "inline_banner", _, _):
            return .banner
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            assertionFailure("Unknown Discover Item: \(type ?? "unknown") \(summaryStyle ?? "unknown")")
            return nil
        }
    }
}

struct DiscoverRowSection: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @Environment(HomeViewModel.self) var localDataModel: HomeViewModel

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
            case .banner:
                makeBannerRow(item: item)
            case .upNext:
                upNextRow
            case .nowPlaying:
                nowPlayingRow
            case .newReleases:
                newReleasesRow
            default:
                DiscoverPodcastRow(item: item, source: source)
            }
        }
    }

    @ViewBuilder
    func makeBannerRow(item: DiscoverItem) -> some View {
        if let bannerId = item.id, let bannerType = BannerType(rawValue: bannerId) {
            BannerRow(type: bannerType, focusSection: HomeView.Section.homeBanner.rawValue) {
                Analytics.track(.bannerRowTapped, properties: ["type": bannerType.rawValue])
                switch bannerType {
                case .discoverMore:
                    tabRouter.selectedTab = .search
                case .createAccount:
                    tabRouter.pendingAuthFlow = .createAccount
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var nowPlayingRow: some View {
        if localDataModel.shouldShowNowPlayingRow, let currentPlaying = localDataModel.currentPlaying {
            RowSection(title: L10n.tvHomeKeepListeningTitle, focusSection: HomeView.Section.homeNowPlaying.rawValue) {
                NowPlayingRow(model: currentPlaying) {
                    tabRouter.showFullScreenPlayer = true
                }
                .frame(width: 1242, alignment: .leading)
                .setFocus(section: HomeView.Section.homeNowPlaying.rawValue)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var upNextRow: some View {
        if localDataModel.upNext.count > 1 {
            EpisodesHorizontalList(title: L10n.tvTabUpNext, focusSection: HomeView.Section.homeUpNext.rawValue, episodes: localDataModel.upNext, episodeContext: .upNext) {
                tabRouter.showFullScreenPlayer = true
            }
        }
    }

    @ViewBuilder
    var newReleasesRow: some View {
        if !localDataModel.newReleases.isEmpty {
            EpisodesHorizontalList(title: L10n.tvHomeNewReleases, focusSection: HomeView.Section.homeNewReleases.rawValue, episodes: localDataModel.newReleases, episodeContext: .other(showGoToPodcast: true)) {
                tabRouter.showFullScreenPlayer = true
            }
        }
    }
}
