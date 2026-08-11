import SwiftUI
import AVKit
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverVideoEpisodeCell: View {

    @Namespace private var ns
    @Environment(FocusStore.self) var focusStore
    @Environment(MainTabViewModel.self) var mainNavigationRouter: MainTabViewModel

    @State private var model: DiscoverVideoEpisodeModel
    @State private var showNotesEpisode: DiscoveryLoadedEpisode?

    private let listId: String?
    private let source: String

    /// Fires just before playback starts, for screens that reuse the cell outside
    /// Discover and need to record their own tap (search results, for instance).
    private let onTap: (() -> Void)?

    @FocusState private var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(72)
        static let cardHeight = CGFloat(402)
        static let cardWidth = CGFloat(716)
        static let fadeDuration: TimeInterval = 0.3
        static let playDelay: TimeInterval = 2
    }

    init(episode: DiscoverEpisode, listId: String? = nil, source: String = "", onTap: (() -> Void)? = nil) {
        _model = State(wrappedValue: DiscoverVideoEpisodeModel(episode: episode, fadeDuration: Layout.fadeDuration, playDelay: Layout.playDelay))
        self.listId = listId
        self.source = source
        self.onTap = onTap
    }

    var body: some View {
        Button {
            trackEpisodeTapped()
            onTap?()
            Task {
                AnalyticsPlaybackHelper.shared.currentSource = AnalyticsSource(rawValue: source)
                let successPlay = await TVDataManager.shared.playEpisode(model.episode)
                await MainActor.run {
                    if successPlay {
                        mainNavigationRouter.showFullScreenPlayer = true
                    } else {
                        ToastManager.shared.show(L10n.playbackFailed)
                    }
                }
            }
        } label: {
            VStack {
                Spacer()
                infoContent
            }
            .padding(32)
            .frame(width: Layout.cardWidth, height: Layout.cardHeight)
            .background {
                ZStack {
                    if isFocused, let player = model.player, model.isPlaying {
                        ZStack {
                            VideoPlayer(player: player)
                                .focusable(false)
                        }
                    } else {
                        backgroundThumbnail
                    }
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .black.opacity(0), location: 0.00),
                            Gradient.Stop(color: .black, location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.59, y: 0.11),
                        endPoint: UnitPoint(x: 0.59, y: 0.81)
                    )
                }
                .transition(.opacity)
                .animation(.smooth(duration: Layout.fadeDuration), value: model.isPlaying)
            }
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    model.play()
                } else {
                    model.pause()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .clipped()
            .focusSection()
            .focusScope(ns)
            // Applied after `scaleEffect` so the shadow renders at its native
            // size — otherwise the cell's 1.1x focus scale enlarges the shadow
            // alongside the cell, making it read as oversized next to pills
            // that scale by only ~1.02x (Up Next, currently-playing).
            .focusedCardDepth(isFocused: isFocused, cornerRadius: 12, style: .content)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut, value: isFocused)
        }
        .focused($isFocused)
        .buttonStyle(ChromelessButtonStyle())
        .task {
            await model.load()
        }
        .sheet(item: $showNotesEpisode) { episode in
            EpisodeShowNotesView(episode: episode.episode, podcast: episode.podcast)
        }
        .contextMenu {
            DiscoveryEpisodeMenuButtons(podcastUuid: model.episode.podcastUuid ?? "", episodeUuid: model.episode.uuid ?? "", showNotesEpisode: $showNotesEpisode, podcast: model.podcast) {
                trackPodcastTapped()
            }
        }
    }

    private func trackEpisodeTapped() {
        guard let listId, let episodeUuid = model.episode.uuid else { return }
        DiscoverAnalytics.episodeTapped(listId: listId, podcastUuid: model.episode.podcastUuid, episodeUuid: episodeUuid, source: source)
        if let podcastUuid = model.episode.podcastUuid {
            DiscoverAnalytics.discoverPodcastPlayed(podcastUuid: podcastUuid, listID: listId)
        }
    }

    private func trackPodcastTapped() {
        guard let listId, let podcastUuid = model.episode.podcastUuid else { return }
        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, source: source)
    }

    var infoContent: some View {
        HStack(alignment: .bottom, spacing: 24) {
            if let podcastUuid = model.episode.podcastUuid {
                PodcastImage(uuid: podcastUuid, size: .list)
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 8) {
                if let title = model.episode.podcastTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.pcTextOnColorSecondary)
                }
                if let description = model.episode.title {
                    Text(description)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.pcTextOnColorPrimary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    var backgroundThumbnail: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.pcBackgroundSunken)
            if let image = model.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
    }
}

#Preview {
    DiscoverVideoEpisodeCell(episode: MockData.makeStubVideoEpisodePodcasts().first!)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
