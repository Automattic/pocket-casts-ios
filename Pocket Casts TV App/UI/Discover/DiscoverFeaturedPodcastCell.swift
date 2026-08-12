import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverFeaturedPodcastCell: View {

    @Namespace private var ns

    let podcast: DiscoverPodcast
    let sponsored: Bool
    let listId: String?
    let source: String

    @FocusState private var focusedButton: FocusValues?

    enum FocusValues {
        case playEpisode
        case goPodcast
    }

    @State var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let imageSize = CGFloat(420)
        static let cardHeight = CGFloat(500)
        static let cardWidth = CGFloat(1604)
    }

    init(podcast: DiscoverPodcast, sponsored: Bool = false, listId: String? = nil, source: String = "") {
        self.podcast = podcast
        self.sponsored = sponsored
        self.listId = listId
        self.source = source
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
                    }
                    .accessibilityElement(children: .combine)
                    HStack(spacing: 24) {
                        Button(L10n.tvDiscoverFeaturedPlayLatestEpisode) {
                            Task {
                                AnalyticsPlaybackHelper.shared.currentSource = .discover
                                let successPlay = await TVDataManager.shared.playLatestEpisode(of: podcast)
                                if successPlay {
                                    trackEpisodeTapped()
                                }
                                await MainActor.run {
                                    if successPlay {
                                        showNowPlayingPlayer = true
                                    } else {
                                        ToastManager.shared.show(L10n.playbackFailed)
                                    }
                                }
                            }
                        }
                        .focused($focusedButton, equals: FocusValues.playEpisode)
                        NavigationLink(value: podcast) {
                            Text(L10n.tvDiscoverFeaturedGoToPodcast)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            guard let podcastUuid = podcast.uuid else {
                                return
                            }
                            if let listId {
                                DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, source: source)
                            }
                            Analytics.track(.discoverFeaturedPodcastTapped, properties: ["uuid": podcastUuid])
                            AnalyticsHelper.openedFeaturedPodcast()
                            DiscoverAnalytics.currentFeaturedPodcast = podcastUuid
                        })
                        .focused($focusedButton, equals: FocusValues.goPodcast)
                    }
                    .padding(.vertical, 24)
                }
                Spacer()
            }
        }
        .padding(48)
        .containerRelativeFrame( .horizontal, alignment: .leading) { length, axis in
            if axis == .vertical {
                return Layout.cardHeight
            } else {
                return length * 0.9
            }
        }
        .blurredCoverBackground(size: Layout.imageSize) {
            if let podcastUuid = podcast.uuid {
                PodcastImage(uuid: podcastUuid, size: .page)
            }
        }
        .background(Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusedCardDepth(isFocused: focusedButton != nil, cornerRadius: 12)
        .scaleEffect(focusedButton != nil ? 1.05 : 1)
        .animation(.default, value: focusedButton)
        .focusSection()
        .focusScope(ns)
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    private func trackEpisodeTapped() {
        guard let episodeUuid = PlaybackManager.shared.currentEpisode?.uuid,
              let podcastUuid = podcast.uuid,
              let listId else {
            return
        }
        DiscoverAnalytics.episodeTapped(listId: listId, podcastUuid: podcastUuid, episodeUuid: episodeUuid, source: source)
        DiscoverAnalytics.discoverPodcastPlayed(podcastUuid: podcastUuid, listID: listId)
    }
}

#Preview {
    DiscoverFeaturedPodcastCell(podcast: MockData.makeStubDiscoveryPodcast())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
