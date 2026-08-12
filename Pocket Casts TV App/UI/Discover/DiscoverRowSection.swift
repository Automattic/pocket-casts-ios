import SwiftUI
import PocketCastsServer
import PocketCastsUtils

enum DiscoverRowType: CaseIterable {
    case categories
    case categoriesPopular
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
    case newVideoReleases
}

extension DiscoverItem {
    var rowType: DiscoverRowType? {
        switch (type, summaryStyle, expandedStyle, sourceType) {
        case ("categories", "pills", _, _), ("categories", "category_list", _, _):
            return .categories
        case ("categories", "popular_category_list", _, _):
            return .categoriesPopular
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
        case ("episode_list", "video_preview_list", _, "new_releases_video"):
            return .newVideoReleases
        case ("banner", "inline_banner", _, _):
            return .banner
        default:
            FileLog.shared.addMessage("Unknown Discover Item: \(type?.uppercased() ?? "unknown") \(summaryStyle ?? "unknown")")
            return nil
        }
    }
}

struct DiscoverRowSection: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

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
            case .categoriesPopular:
                DiscoverCategoriesRow(item: item, popularOnly: true, source: source)
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
            case .newVideoReleases:
                newVideoReleasesRow
            case .listPodcast:
                DiscoverPodcastRow(item: item, source: source)
            case nil:
                EmptyView()
            }
        }
        .task {
        #if DEBUG || STAGING
            if item.rowType == nil {
                ToastManager.shared.show("UNKNOWN DISCOVER ITEM: \(item.type ?? "unknow"), CHECK CONSOLE!")
            }
        #endif
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
        if tabRouter.homeModel.shouldShowNowPlayingRow,
           let currentPlaying = tabRouter.homeModel.currentPlaying {
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
        if tabRouter.homeModel.upNext.count > 1 {
            EpisodesHorizontalList(title: L10n.tvTabUpNext,
                                   focusSection: HomeView.Section.homeUpNext.rawValue,
                                   episodes: tabRouter.homeModel.upNext, episodeContext: .upNext) {
                tabRouter.showFullScreenPlayer = true
            }
        }
    }

    @ViewBuilder
    var newReleasesRow: some View {
        if !tabRouter.homeModel.newReleases.isEmpty {
            EpisodesHorizontalList(title: L10n.tvHomeNewReleases,
                                   focusSection: HomeView.Section.homeNewReleases.rawValue,
                                   episodes: tabRouter.homeModel.newReleases, episodeContext: .other(showGoToPodcast: true)) {
                tabRouter.showFullScreenPlayer = true
            }
        }
    }

    @ViewBuilder
    var newVideoReleasesRow: some View {
        if !tabRouter.homeModel.newVideoReleases.isEmpty {
            VideoEpisodesHorizontalList(title: L10n.newEpisodes,
                                   focusSection: HomeView.Section.homeNewVideoReleases.rawValue,
                                   episodes: tabRouter.homeModel.newVideoReleases, episodeContext: .other(showGoToPodcast: true)) {
                tabRouter.showFullScreenPlayer = true
            }
        }
    }
}
