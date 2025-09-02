import SwiftUI
import PocketCastsServer

struct DiscoverPodcastsGridView: View {
    let category: DiscoverCategory
    let podcasts: [DiscoverPodcast]

    enum Constants {
        static let itemHeight: CGFloat = 148
        static let gridSpacing: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let coverSize: CGFloat = 108
        static let textHeight: CGFloat = 32
    }

    let columns = [
        GridItem(.flexible(), spacing: Constants.itemSpacing),
        GridItem(.flexible(), spacing: Constants.itemSpacing),
        GridItem(.flexible())
    ]

    @State var visibleCount: Int = 6
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: columns, spacing: Constants.gridSpacing) {
                ForEach(Array(podcasts.prefix(visibleCount)), id: \.uuid) { podcast in
                    podcastItem(podcast)
                }
            }
            .padding(.horizontal, 20)

            if podcasts.count > visibleCount {
                Button(action: {
                    OnboardingFlow.shared.track(.recommendationsMoreTapped, properties: ["title": category.name ?? "Unknown", "number_visible": visibleCount])
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
        VStack(alignment: .leading, spacing: Constants.itemSpacing) {
            PodcastCover(podcastUuid: podcast.uuid ?? "")
                .frame(width: Constants.coverSize, height: Constants.coverSize)

                .cornerRadius(8)
                .overlay {
                    PodcastSubscribeButton(podcast: podcast)
                }

            Text(podcast.title ?? "")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.primaryText01)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: Constants.textHeight, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.itemHeight)
    }

}
