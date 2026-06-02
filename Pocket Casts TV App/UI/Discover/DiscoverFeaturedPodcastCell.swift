import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverFeaturedPodcastCell: View {

    @Namespace private var ns

    let podcast: DiscoverPodcast
    let sponsored: Bool

    @Environment(\.isFocused) var isFocused: Bool

    @State var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let imageSize = CGFloat(420)
        static let cardHeight = CGFloat(500)
        static let cardWidth = CGFloat(1604)
    }

    init(podcast: DiscoverPodcast, sponsored: Bool = false) {
        self.podcast = podcast
        self.sponsored = sponsored
    }

    var body: some View {
        ZStack(alignment: .center) {
            HStack(alignment: .center, spacing: 48) {
                if let podcastUuid = podcast.uuid {
                    PodcastImage(uuid: podcastUuid, size: .page)
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        if sponsored {
                            Text(L10n.discoverSponsored.sentenceCased)
                                .font(.body)
                                .foregroundColor(.pcTextPrimary)
                            Text("·")
                                .foregroundColor(.pcTextSecondary)
                        }
                        if let author = podcast.author {
                            Text(author)
                                .font(.body)
                                .foregroundColor(.pcTextSecondary)
                        }
                        Spacer()
                    }
                    if let title = podcast.title {
                        Text(title)
                            .font(.title2)
                            .foregroundColor(.pcTextPrimary)
                    }
                    if let description = podcast.shortDescription {
                        Text(description)
                            .lineLimit(2)
                            .font(.body)
                            .foregroundColor(.pcTextSecondary)
                    }
                    HStack() {
                        Button(L10n.tvDiscoverFeaturedPlayLatestEpisode) {
                            Task {
                                let _ = await TVDataManager.shared.playLatestEpisode(of: podcast)
                                await MainActor.run {
                                    showNowPlayingPlayer = true
                                }
                            }
                        }
                        NavigationLink(value: podcast) {
                            Text(L10n.tvDiscoverFeaturedGoToPodcast)
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
            if let podcastUuid = podcast.uuid {
                PodcastImage(uuid: podcastUuid, size: .page)
            }
        }
        .background(Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
        .focusSection()
        .focusScope(ns)
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    DiscoverFeaturedPodcastCell(podcast: MockData.makeStubDiscoveryPodcast())
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
