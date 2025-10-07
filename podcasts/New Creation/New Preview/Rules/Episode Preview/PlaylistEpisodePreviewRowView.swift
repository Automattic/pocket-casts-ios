import SwiftUI
import PocketCastsDataModel

struct PlaylistEpisodePreviewRowView: View {
    @EnvironmentObject var theme: Theme

    let episode: BaseEpisode
    let hideSeparator: Bool

    var subtitle: String {
        let timeLeft = episode.displayableTimeLeft()
        return episode.archived ? "\(L10n.podcastArchived) • \(timeLeft)" : timeLeft
    }

    init(episode: BaseEpisode, hideSeparator: Bool = false) {
        self.episode = episode
        self.hideSeparator = hideSeparator
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Rectangle()
                    .fill(theme.primaryUi05)
                    .frame(height: 1)
                    .if(hideSeparator) {
                        $0.hidden()
                    }
            }
            HStack(spacing: 11.0) {
                PlaylistEpisodeImageViewWrapper(
                    episode: episode,
                    size: .list
                )
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(EpisodeDateHelper.formattedDate(for: episode))
                        .font(size: 11.0, style: .body, weight: .semibold)
                        .foregroundStyle(theme.primaryText02)
                    Text(episode.title ?? "")
                        .font(size: 15.0, style: .body, weight: .medium)
                        .foregroundStyle(theme.primaryText01)
                    HStack {
                        if episode.archived {
                            Image("list_archived")
                                .renderingMode(.template)
                                .resizable()
                                .foregroundColor(theme.primaryText02)
                                .frame(width: 12, height: 12)
                        }
                        Text(subtitle)
                            .font(size: 12.0, style: .body, weight: .semibold)
                            .foregroundStyle(theme.primaryText02)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .opacity(episode.archived ? 0.5 : 1.0)
    }
}

fileprivate struct PlaylistEpisodeImageViewWrapper: UIViewRepresentable {
    let episode: BaseEpisode
    let size: PodcastThumbnailSize

    func makeUIView(context: Context) -> PodcastImageView {
        PodcastImageView()
    }

    func updateUIView(_ podcastImageView: PodcastImageView, context: Context) {
        if let userEpisode = episode as? UserEpisode {
            podcastImageView.setUserEpisode(uuid: userEpisode.uuid, size: size)
        } else {
            podcastImageView.setPodcast(uuid: episode.parentIdentifier(), size: size)
        }
    }
}
