import SwiftUI
import PocketCastsDataModel

struct PlaylistEpisodePreviewRowView: View {
    @EnvironmentObject var theme: Theme

    let episode: BaseEpisode
    let hideSeparator: Bool

    var subtitle: String {
        let timeLeft = episode.displayableTimeLeft()
        if episode.wasDeleted {
            return "\(L10n.podcastUnavailable) • \(timeLeft)"
        } else if episode.archived {
            return "\(L10n.podcastArchived) • \(timeLeft)"
        }
        return timeLeft
    }

    var subtitleImage: String? {
        if episode.wasDeleted {
            return "option-cross-circle"
        } else if episode.archived {
            return "list_archived"
        }
        return nil
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
                    HStack(spacing: 4) {
                        if let subtitleImage {
                            Image(subtitleImage)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        Text(subtitle)
                        Spacer()
                    }
                    .font(size: 12.0, style: .body, weight: .semibold)
                    .foregroundStyle(theme.primaryText02)
                }
                Spacer()
            }
        }
        .opacity(episode.played() || episode.archived || episode.wasDeleted ? 0.5 : 1.0)
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
