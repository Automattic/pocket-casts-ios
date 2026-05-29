import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverFeaturedPodcastCell: View {

    @Namespace private var ns

    let podcast: DiscoverPodcast

    @Environment(\.isFocused) var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(420)
        static let rotationEffect = CGFloat(15)
        static let cardHeight = CGFloat(500)
        static let cardWidth = CGFloat(1604)
        static let iconSize = CGFloat(48)
    }

    init(podcast: DiscoverPodcast) {
        self.podcast = podcast
    }

    var body: some View {
        ZStack(alignment: .center) {
            HStack(alignment: .center, spacing: 48) {
                PodcastImage(uuid: podcast.uuid!, size: .page)
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    if let author = podcast.author {
                        Text(author)
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    if let title = podcast.title {
                        Text(title)
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                    }
                    if let description = podcast.shortDescription {
                        Text(description)
                            .lineLimit(2)
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    HStack() {
                        Button("Play latest episode") {
                        }
                        NavigationLink(value: podcast) {
                            Text("Go to podcast")
                        }
                    }
                    .padding(.vertical, 24)
                }
                Spacer()
            }
        }
        .padding(48)
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
        .blurredCoverBackground(size: Layout.imageSize) {
            PodcastImage(uuid: podcast.uuid!, size: .page)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
        .focusSection()
        .focusScope(ns)
    }
}

#Preview {
    DiscoverFeaturedPodcastCell(podcast: MockData.makeStubDiscoveryPodcast())
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
