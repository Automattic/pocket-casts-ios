import SwiftUI
import PocketCastsServer

struct DiscoverPodcastsGridView: View {
    let category: DiscoverCategory
    let podcasts: [DiscoverPodcast]

    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible())
    ]

    @State var visibleCount: Int = 6
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(podcasts.prefix(visibleCount)), id: \.uuid) { podcast in
                    podcastItem(podcast)
                }
            }
            .padding(.horizontal, 20)

            if podcasts.count > visibleCount {
                Button(action: {
                    visibleCount = min(visibleCount + 6, podcasts.count)
                }) {
                    Text("More \(category.name ?? "Unknown")")
                        .textStyle(BorderButton())
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder func podcastItem(_ podcast: DiscoverPodcast) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PodcastCover(podcastUuid: podcast.uuid ?? "")
                .frame(width: 108, height: 108)
                .cornerRadius(8)
                .overlay {
                    PodcastSubscribeButton(podcast: podcast)
                }

            Text(podcast.title ?? "")
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 32, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 148)
    }

}
