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
                EmptyDataView(title: "Unable to load discover")
            }
        }
        .task {
            await model.load()
        }
    }

    var discoverList: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(model.sections.enumerated()), id: \.offset) { _, item in
                    HomeSection(title: item.title ?? "", focusSection: item.uuid) {
                        switch item.rowType {
                        case .categories:
                            DiscoverCategoriesRow(popularOnly: false)
                        case .featured:
                            DiscoverFeaturedPodcastsRow(type: .featured)
                        case .listPodcast:
                            DiscoverPodcastRow(item: item)
                        case .singlePodcast:
                            DiscoverSinglePodcastRow(item: item)
                        default:
                            DiscoverPodcastRow(item: item)
                        }
                    }
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
