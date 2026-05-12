import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct ShareProfileCardView: View {
    @ObservedObject var viewModel: ShareProfileViewModel

    private let podcasts: [Podcast]
    private let episodes: [Episode]
    private let playlists: [EpisodeFilter]

    init(viewModel: ShareProfileViewModel) {
        self.viewModel = viewModel
        self.podcasts = viewModel.shareFollowedPodcasts
            ? Array(viewModel.followedPodcasts.prefix(9))
            : []
        self.episodes = viewModel.shareRecentEpisodes
            ? Array(viewModel.recentEpisodes.prefix(5))
            : []
        self.playlists = viewModel.sharePlaylists
            ? viewModel.playlists
            : []
    }

    var body: some View {
        VStack(spacing: 16) {
            profileSection()

            if viewModel.shareFollowedPodcasts && !podcasts.isEmpty {
                podcastsGrid()
            }

            if viewModel.shareRecentEpisodes && !episodes.isEmpty {
                episodesSection()
            }

            if viewModel.sharePlaylists && !playlists.isEmpty {
                playlistsSection()
            }

            Spacer(minLength: 0)

            branding()
        }
        .padding(24)
        .background(Color(.systemBackground))
    }

    // MARK: - Profile

    @ViewBuilder
    private func profileSection() -> some View {
        VStack(spacing: 8) {
            if let photo = viewModel.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            }

            if !viewModel.displayName.isEmpty {
                Text(viewModel.displayName)
                    .font(.title3.bold())
            }
        }
    }

    // MARK: - Podcasts Grid

    @ViewBuilder
    private func podcastsGrid() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.shareProfileFollowedPodcasts.uppercased())
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(podcasts, id: \.uuid) { podcast in
                    PodcastCoverView(uuid: podcast.uuid)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Episodes

    @ViewBuilder
    private func episodesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.shareProfileRecentEpisodes.uppercased())
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            ForEach(episodes, id: \.uuid) { episode in
                HStack(spacing: 8) {
                    PodcastCoverView(uuid: episode.podcastUuid)
                        .frame(width: 32, height: 32)
                        .cornerRadius(4)

                    Text(episode.title ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Playlists

    @ViewBuilder
    private func playlistsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.shareProfilePlaylists.uppercased())
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            ForEach(playlists.prefix(5), id: \.uuid) { playlist in
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(playlist.playlistName)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Branding

    @ViewBuilder
    private func branding() -> some View {
        Image("pc-logo-vertical")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 32)
    }
}

// MARK: - Podcast Cover

private struct PodcastCoverView: View {
    let uuid: String

    var body: some View {
        let url = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: uuid)
        AsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Preview

struct ShareProfileCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileCardView(viewModel: ShareProfileViewModel())
            .frame(width: 390, height: 520)
            .previewLayout(.sizeThatFits)
    }
}
