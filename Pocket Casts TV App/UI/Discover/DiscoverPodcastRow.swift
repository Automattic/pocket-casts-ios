import SwiftUI
import PocketCastsServer

struct DiscoverPodcastRow: View {

    fileprivate enum Layout {
        static let gridSize = CGFloat(250)
    }

    @State private var model: DiscoverSectionModel

    init(type: DiscoverType) {
        _model = State(wrappedValue: DiscoverSectionModel(type: type))
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0, content: {
                ForEach(model.podcasts) { podcast in
                    if let uuid = podcast.uuid {
                        NavigationLink(value: podcast) {
                            PodcastImage(uuid: uuid, size: .page)
                                .frame(width: Layout.gridSize, height: Layout.gridSize)
                        }
                        .buttonStyle(.card)
                        .padding(24)
                    }
                }
            })
            .navigationDestination(for: DiscoverPodcast.self) { podcast in
                if let uuid = podcast.uuid {
                    PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid))
                }
            }
        }
        .task {
            await model.load()
        }
    }
}
