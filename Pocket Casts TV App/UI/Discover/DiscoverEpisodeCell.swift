import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct DiscoverEpisodeCell: View {

    private let episode: DiscoverEpisode
    private let listId: String?
    private let source: String

    /// Fires just before playback starts, for screens that reuse the cell outside
    /// Discover and need to record their own tap (search results, for instance).
    private let onTap: (() -> Void)?

    @State private var showNotesEpisode: DiscoveryLoadedEpisode?
    @State private var showNowPlayingPlayer: Bool = false

    @FocusState private var isFocused: Bool

    enum Layout {
        static let imageSize = CGFloat(124)
    }

    init(episode: DiscoverEpisode, listId: String? = nil, source: String = "", onTap: (() -> Void)? = nil) {
        self.episode = episode
        self.listId = listId
        self.source = source
        self.onTap = onTap
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let podcastUuid = episode.podcastUuid {
            PodcastImage(uuid: podcastUuid, size: .list)
        } else {
            EmptyView()
        }
    }

    var body: some View {
        Button {
            trackEpisodeTapped()
            onTap?()
            Task {
                let successPlay = await TVDataManager.shared.playEpisode(episode)
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
                    Text(episode.podcastTitle ?? "")
                        .font(.caption)
                        .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    Text(episode.title ?? "")
                        .font(.body)
                        .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                        .lineLimit(2)
                    if let duration = episode.duration {
                        Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(duration)))
                            .font(.caption)
                            .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer()
            }
            .padding(32)
            .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .focused($isFocused)
        .buttonStyle(ChromelessButtonStyle())
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
        .sheet(item: $showNotesEpisode) { episode in
            EpisodeShowNotesView(episode: episode.episode, podcast: episode.podcast)
        }
        .contextMenu {
            DiscoveryEpisodeMenuButtons(podcastUuid: episode.podcastUuid ?? "", episodeUuid: episode.uuid ?? "", showNotesEpisode: $showNotesEpisode, podcast: episode.discoverPodcast) {
                trackPodcastTapped()
            }
        }
    }

    private func trackEpisodeTapped() {
        guard let listId, let episodeUuid = episode.uuid else { return }
        DiscoverAnalytics.episodeTapped(listId: listId, podcastUuid: episode.podcastUuid, episodeUuid: episodeUuid, source: source)
        if let podcastUuid = episode.podcastUuid {
            DiscoverAnalytics.discoverPodcastPlayed(podcastUuid: podcastUuid, listID: listId)
        }
    }

    private func trackPodcastTapped() {
        guard let listId, let podcastUuid = episode.podcastUuid else { return }
        DiscoverAnalytics.podcastTapped(listId: listId, podcastUuid: podcastUuid, source: source)
    }
}

#Preview {
    DiscoverEpisodeCell(episode: MockData.makeStubVideoEpisodePodcasts().first!)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
