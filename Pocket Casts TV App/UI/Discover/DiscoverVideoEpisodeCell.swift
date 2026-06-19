import SwiftUI
import AVKit
import PocketCastsDataModel
import PocketCastsServer
import Kingfisher

struct DiscoverVideoEpisodeCell: View {

    @Namespace private var ns
    @Environment(FocusStore.self) var focusStore

    @State private var model: DiscoverVideoEpisodeModel
    @State private var showNotesEpisode: DiscoveryLoadedEpisode?

    private let listId: String?
    private let source: String

    enum FocusValues {
        case playEpisode
        case goPodcast
    }

    @FocusState private var focusedButton: FocusValues?
    @State private var lastFocusedButton: FocusValues? = nil
    @FocusState private var isContainerFocused: Bool

    @State private var isFocused = false
    @State private var isAnimating = false

    @State var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let imageSize = CGFloat(72)
        static let cardHeight = CGFloat(402)
        static let cardWidth = CGFloat(716)
        static let fadeDuration: TimeInterval = 0.5
        static let playDelay: TimeInterval = 2
    }

    init(episode: DiscoverEpisode, listId: String? = nil, source: String = "") {
        _model = State(wrappedValue: DiscoverVideoEpisodeModel(episode: episode, fadeDuration: Layout.fadeDuration, playDelay: Layout.playDelay))
        self.listId = listId
        self.source = source
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
        .background {
            Group {
                if isFocused, let player = model.player, model.isPlaying {
                    VideoPlayer(player: player)
                        .focusable(false)
                } else {
                    backgroundThumbnail
                }
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
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut, value: isFocused)
        .onChange(of: focusedButton) { _, focused in
            if let focused {
                lastFocusedButton = focused
            }
            if focused == nil, isFocused, !isAnimating {
                collapse()
            }
        }
        .task {
            await model.load()
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
        .sheet(item: $showNotesEpisode) { episode in
            EpisodeShowNotesView(episode: episode.episode, podcast: episode.podcast)
        }
    }

    private func trackEpisodeTapped() {
        guard let listId, let episodeUuid = model.episode.uuid else { return }
        DiscoverAnalytics.episodeTapped(listId: listId, podcastUuid: model.episode.podcastUuid, episodeUuid: episodeUuid, source: source)
    }

    private func trackPodcastTapped() {
        guard let listId, let podcastUuid = model.episode.podcastUuid else { return }
        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, source: source)
    }

    private func expand() {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.2)) {
            isFocused = true
        } completion: {
            isAnimating = false
            focusedButton = lastFocusedButton ?? .playEpisode
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
        .focused($isContainerFocused)
        .setFocus(section: DiscoverType.video.rawValue)
        .buttonStyle(ChromelessButtonStyle())
        .onChange(of: isContainerFocused) { _, focused in
            if focused, !isAnimating {
                expand()
            }
        }
    }

    var focusedContent: some View {
        HStack(alignment: .bottom, spacing: 16) {
            Button(L10n.tvDiscoverPlayEpisode) {
                trackEpisodeTapped()
                Task {
                    let successPlay = await TVDataManager.shared.playEpisode(model.episode)
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
            .setFocus(section: DiscoverType.video.rawValue)
            .contextMenu {
                DiscoveryEpisodeMenuButtons(podcastUuid: model.episode.podcastUuid ?? "", episodeUuid: model.episode.uuid ?? "", showNotesEpisode: $showNotesEpisode)
            }
            if let podcast = model.podcast {
                NavigationLink(value: podcast) {
                    Text(L10n.tvDiscoverFeaturedGoToPodcast)
                }
                .focused($focusedButton, equals: FocusValues.goPodcast)
                .setFocus(section: DiscoverType.video.rawValue)
                .simultaneousGesture(TapGesture().onEnded {
                    trackPodcastTapped()
                })
            }
            Spacer()
        }
        // These buttons always sit over the card's black gradient overlay, so force the
        // dark color scheme to keep the default tvOS button readable (light label / bright
        // focus pill) in light mode too.
        .environment(\.colorScheme, .dark)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    var nonFocusedContent: some View {
        Group {
            HStack(alignment: .bottom, spacing: 48) {
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
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black.opacity(0), location: 0.00),
                    Gradient.Stop(color: .black, location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.59, y: 0.11),
                endPoint: UnitPoint(x: 0.59, y: 0.81)
            )
        }
    }
}

#Preview {
    DiscoverVideoEpisodeCell(episode: MockData.makeStubVideoEpisodePodcasts().first!)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
