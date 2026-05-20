import SwiftUI
import PocketCastsDataModel

struct SearchPodcastsResultsView: View {

    let podcastsUuids: [String]

    enum Layout {
        static let cellSize = CGFloat(250)
    }

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.cellSize), spacing: 48)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(podcastsUuids, id: \.self) { podcast in
                    NavigationLink(value: podcast) {
                        PodcastImage(uuid: podcast, size: .page)
                            .frame(width: Layout.cellSize, height: Layout.cellSize)
                    }
                    .buttonStyle(.card)
                }
            })
            .navigationDestination(for: String.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast))
            }
        }
    }
}
