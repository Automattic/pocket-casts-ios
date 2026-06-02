import SwiftUI
import AVKit
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverVideoEpisodeCell: View {

    @Namespace private var ns

    let episode: DiscoverEpisode

    @FocusState private var focusedButton: Int?
    @State private var lastFocusedButton: Int? = nil
    @FocusState private var isContainerFocused: Bool

    @State private var isFocused = false
    @State private var isAnimating = false

    @State var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let imageSize = CGFloat(72)
        static let cardHeight = CGFloat(402)
        static let cardWidth = CGFloat(716)
    }

    init(episode: DiscoverEpisode) {
        self.episode = episode
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            //VideoPlayer(player: AVPlayer(url: URL(string: episode.url!)!))
            placeholderFocusView
            VStack {
                Spacer()
                if isFocused {
                    focusedContent
                } else {
                    nonFocusedContent
                }
            }
        }
        .padding(32)
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
        .background(Color.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
        .focusSection()
        .onChange(of: focusedButton) { _, focused in
            if let focused {
                lastFocusedButton = focused
            }
            if focused == nil, isFocused, !isAnimating {
                collapse()
            }
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    private func expand() {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.2)) {
            isFocused = true
        } completion: {
            isAnimating = false
            focusedButton = lastFocusedButton ?? 0
        }
    }

    private func collapse() {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.2)) {
            isFocused = false
        } completion: {
            isAnimating = false
        }
    }

    var placeholderFocusView: some View {
        Rectangle()
        .foregroundStyle(.clear)
        .focusable(!isFocused)
        .setFocus(section: DiscoverType.video)
        .focused($isContainerFocused)
        .buttonStyle(ChromelessButtonStyle())
        .onChange(of: isContainerFocused) { _, focused in
            if focused, !isAnimating {
                expand()
            }
        }
    }

    var focusedContent: some View {
        HStack(alignment: .bottom) {
            Button("Play episode") {
                Task {
                    await MainActor.run {
                        showNowPlayingPlayer = true
                    }
                }
            }
            .focused($focusedButton, equals: 0)
            .setFocus(section: DiscoverType.video)
            if let podcast = episode.discoverPodcast {
                NavigationLink(value: podcast) {
                    Text(L10n.tvDiscoverFeaturedGoToPodcast)
                }
                .focused($focusedButton, equals: 1)
                .setFocus(section: DiscoverType.video)
            }
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    var nonFocusedContent: some View {
        Group {
            HStack(alignment: .bottom, spacing: 48) {
                if let podcastUuid = episode.podcastUuid {
                    PodcastImage(uuid: podcastUuid, size: .page)
                        .frame(width: Layout.imageSize, height: Layout.imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 8) {
                    if let title = episode.podcastTitle {
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    if let description = episode.title {
                        Text(description)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                    }
                }
                Spacer()
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

extension DiscoverEpisode {

    var discoverPodcast: DiscoverPodcast? {
        guard let podcastUuid = self.podcastUuid else {
            return nil
        }
        var podcast = DiscoverPodcast()
        podcast.uuid = podcastUuid
        podcast.title = self.podcastTitle
        return podcast
    }
}

#Preview {
    DiscoverVideoEpisodeCell(episode: MockData.makeStubVideoEpisodePodcasts().first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
