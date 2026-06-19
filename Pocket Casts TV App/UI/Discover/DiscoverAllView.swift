import SwiftUI
import PocketCastsServer

struct DiscoverAllView: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model = DiscoverAllViewModel()

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .ready:
                discoverList
            case .empty:
                ContentUnavailableView {
                    Text(L10n.tvDiscoverFailedToLoadTitle)
                } description: {
                    Text(L10n.tvDiscoverFailedToLoadSubtitle)
                }
            }
        }
        .task {
            await model.load()
        }
    }

    var discoverList: some View {
        ScrollView {
            LazyVStack(spacing: HomeSectionLayout.sectionSpacing) {
                ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                    DiscoverRowSection(item: item, source: DiscoverAnalytics.searchSource)
                }
            }
        }
        .navigationDestination(for: DiscoverPodcast.self) { podcast in
            if let uuid = podcast.uuid {
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid))
            }
        }
        .navigationDestination(for: DiscoverCategory.self) { discoverCategory in
            DiscoverPodcastsListView(category: discoverCategory)
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
                DiscoverCategoriesRow(popularOnly: false, source: source)
            case .featured:
                DiscoverFeaturedPodcastsRow(item: item, source: source)
            case .listVideoEpisode:
                DiscoverVideoEpisodesRow(item: item, source: source)
            case .singlePodcast:
                DiscoverSinglePodcastRow(item: item, source: source)
            default:
                DiscoverPodcastRow(item: item, source: source)
            }
        }
    }
}

extension DiscoverItem {

    var focusStoreID: String {
        self.uuid ?? self.id ?? self.type ?? ""
    }
}
