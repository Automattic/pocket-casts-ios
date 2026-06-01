import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct SharedProfileEpisodeList: View {
    @EnvironmentObject var theme: Theme
    let episodes: [SharedProfileViewModel.EpisodeInfo]
    let navigateToEpisode: (_ uuid: String, _ podcastUuid: String) -> Void
    let playEpisode: (_ uuid: String, _ podcastUuid: String) -> Void
    let goBack: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
                    SharedProfileEpisodeRow(
                        episode: episode,
                        navigateToEpisode: { navigateToEpisode(episode.uuid, episode.podcastUuid) },
                        playEpisode: { playEpisode(episode.uuid, episode.podcastUuid) }
                    )

                    if index < episodes.count - 1 {
                        ThemedDivider()
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileRecentEpisodes)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: goBack) {
                    Image("nav-back")
                        .renderingMode(.template)
                }
                .navThemed()
            }
        }
    }
}

struct SharedProfileEpisodeRow: View {
    @EnvironmentObject var theme: Theme
    let episode: SharedProfileViewModel.EpisodeInfo
    let navigateToEpisode: () -> Void
    let playEpisode: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: navigateToEpisode) {
                HStack(spacing: 12) {
                    PodcastImage(uuid: episode.podcastUuid, size: .list)
                        .frame(width: 56, height: 56)
                        .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 2) {
                        if let date = episode.publishedDate {
                            Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase)
                                .font(style: .caption2, weight: .bold)
                                .foregroundColor(theme.primaryText02)
                        }

                        Text(episode.title)
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(theme.primaryText01)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            if let podcastTitle = episode.podcastTitle {
                                Text(podcastTitle)
                                    .lineLimit(1)
                                Text("·")
                            }
                            Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: episode.duration))
                        }
                        .font(style: .caption, weight: .semibold)
                        .foregroundColor(theme.primaryText02)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: playEpisode) {
                EpisodePlayButton()
            }
            .accessibilityLabel(L10n.play)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
