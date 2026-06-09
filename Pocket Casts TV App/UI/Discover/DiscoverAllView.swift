import SwiftUI
import PocketCastsServer

struct DiscoverAllView: View {

    @State private var model = DiscoverAllViewModel()

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView()
            case .ready:
                discoverList
            case .empty:
                EmptyDataView(title: L10n.tvDiscoverFailedToLoadTitle, subtitle: L10n.tvDiscoverFailedToLoadSubtitle)
            }
        }
        .task {
            await model.load()
        }
    }

    var discoverList: some View {
        ScrollView {
            LazyVStack(spacing: 80) {
                ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                    DiscoverRowSection(item: item)
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

    @State var title: String

    init(item: DiscoverItem) {
        self.item = item
        _title = State<String>(initialValue: item.title?.localized ?? "")
    }

    var body: some View {
        HomeSection(title: title, focusSection: item.focusStoreID) {
            switch item.rowType {
            case .categories:
                DiscoverCategoriesRow(popularOnly: false)
            case .featured:
                DiscoverFeaturedPodcastsRow(item: item)
            case .listVideoEpisode:
                DiscoverVideoEpisodesRow(item: item)
            case .singlePodcast:
                DiscoverSinglePodcastRow(item: item) { title in
                    if item.isSponsored == true {
                        self.title = L10n.tvSponsoredPodcastSectionTitle
                    } else {
                        if let title {
                            self.title = title
                        }
                    }
                }
            default:
                DiscoverPodcastRow(item: item) { title in
                    if let title {
                        self.title = title
                    }
                }
            }
        }
    }
}

extension DiscoverItem {

    var focusStoreID: String {
        self.uuid ?? self.id ?? self.type ?? ""
    }
}
