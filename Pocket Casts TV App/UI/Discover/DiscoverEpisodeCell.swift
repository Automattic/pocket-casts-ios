import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct DiscoverEpisodeCell: View {

    @Namespace private var ns
    @Environment(FocusStore.self) var focusStore

    @State private var model: DiscoverEpisodeModel
    @State private var showNotesEpisode: DiscoveryLoadedEpisode?

    private let listId: String?
    private let source: String

    @FocusState private var isFocused: Bool

    @State var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let imageSize = CGFloat(124)
        static let cardHeight = CGFloat(402)
        static let cardWidth = CGFloat(716)
    }

    init(episode: DiscoverEpisode, listId: String? = nil, source: String = "") {
        _model = State(wrappedValue: DiscoverEpisodeModel(episode: episode))
        self.listId = listId
        self.source = source
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let podcastUuid = model.episode.podcastUuid {
            PodcastImage(uuid: podcastUuid, size: .list)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        Button {
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
        } label: {
            HStack(spacing: 24) {
                thumbnail
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading) {
                    Text(model.episode.podcastTitle ?? "")
                        .font(.caption)
                        .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    Text(model.episode.title ?? "")
                        .font(.body)
                        .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                        .lineLimit(2)
                    if let duration = model.episode.duration {
                        Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(duration)))
                            .font(.caption)
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    }
                }
                Spacer()
            }
            .padding(32)
            .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .focused($isFocused)
        .buttonStyle(ChromelessButtonStyle())
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
    }
}

#Preview {
    DiscoverEpisodeCell(episode: MockData.makeStubVideoEpisodePodcasts().first!)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
