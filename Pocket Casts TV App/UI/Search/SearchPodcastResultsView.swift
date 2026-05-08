import SwiftUI
import PocketCastsDataModel

struct SearchPodcastsResultsView: View {

    let podcasts: [Podcast]

    enum Layout {
        static let cellSize = CGFloat(250)
    }

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.cellSize), spacing: 48)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(podcasts) { podcast in
                    NavigationLink(value: podcast) {
                        PodcastImageViewWrapper(podcastUUID: podcast.uuid, size: .page)
                            .frame(width: Layout.cellSize, height: Layout.cellSize)
                    }
                    .buttonStyle(.card)
                }
            })
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
            }
        }
    }
}
