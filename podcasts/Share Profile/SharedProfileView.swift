import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct SharedProfileView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SharedProfileViewModel

    enum Page {
        case allPodcasts
        case allEpisodes
    }

    @State private var path: [Page] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Page.self) { page in
                    switch page {
                    case .allPodcasts:
                        allPodcastsView()
                    case .allEpisodes:
                        allEpisodesView()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .navThemed()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.primaryUi01)

        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(theme.primaryText02)
                Text(message)
                    .font(style: .body)
                    .foregroundColor(theme.primaryText02)
                    .multilineTextAlignment(.center)
                Button(L10n.retry) {
                    // TODO: retry
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryUi01)

        case .loaded(let profile):
            profileContent(profile)
        }
    }

    // MARK: - Profile Content

    @ViewBuilder
    private func profileContent(_ profile: SharedProfileViewModel.ProfileData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(profile)

                if !profile.podcasts.isEmpty {
                    podcastsSection(profile.podcasts)
                }

                if !profile.episodes.isEmpty {
                    episodesSection(profile.episodes)
                }
            }
            .padding(.bottom, 32)
        }
        .background(theme.primaryUi01)
    }

    // MARK: - Header

    @ViewBuilder
    private func profileHeader(_ profile: SharedProfileViewModel.ProfileData) -> some View {
        VStack(spacing: 12) {
            if let photoURL = profile.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    profilePlaceholder
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                profilePlaceholder
            }

            Text(profile.displayName)
                .font(style: .title2, weight: .bold)
                .foregroundColor(theme.primaryText01)
        }
        .padding(.top, 24)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(.systemGray3))
            )
    }

    // MARK: - Podcasts Section

    @ViewBuilder
    private func podcastsSection(_ podcasts: [SharedProfileViewModel.PodcastInfo]) -> some View {
        VStack(spacing: 0) {
            sectionHeader(L10n.shareProfileFollowedPodcasts) {
                path.append(.allPodcasts)
            }

            ForEach(Array(podcasts.prefix(3).enumerated()), id: \.element.id) { index, podcast in
                podcastRow(podcast)

                if index < min(podcasts.count, 3) - 1 {
                    ThemedDivider()
                        .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func podcastRow(_ podcast: SharedProfileViewModel.PodcastInfo) -> some View {
        HStack(spacing: 12) {
            podcastArtwork(url: podcast.artworkURL, size: 52)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(podcast.title)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(1)

                if let author = podcast.author {
                    Text(author)
                        .font(style: .footnote, weight: .regular)
                        .foregroundColor(theme.primaryText02)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Episodes Section

    @ViewBuilder
    private func episodesSection(_ episodes: [SharedProfileViewModel.EpisodeInfo]) -> some View {
        VStack(spacing: 0) {
            sectionHeader(L10n.shareProfileRecentEpisodes) {
                path.append(.allEpisodes)
            }

            ForEach(Array(episodes.prefix(3).enumerated()), id: \.element.id) { index, episode in
                episodeRow(episode)

                if index < min(episodes.count, 3) - 1 {
                    ThemedDivider()
                        .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func episodeRow(_ episode: SharedProfileViewModel.EpisodeInfo) -> some View {
        HStack(spacing: 12) {
            podcastArtwork(url: episode.artworkURL, size: 56)

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

                Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: episode.duration))
                    .font(style: .caption, weight: .semibold)
                    .foregroundColor(theme.primaryText02)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Artwork

    private func podcastArtwork(url: URL?, size: CGFloat) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
        }
        .frame(width: size, height: size)
        .cornerRadius(4)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, showAllAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(style: .headline, weight: .bold)
                .foregroundColor(theme.primaryText01)
            Spacer()
            if let showAllAction {
                Button(action: showAllAction) {
                    Text(L10n.discoverShowAll)
                        .font(style: .caption, weight: .bold)
                        .foregroundColor(theme.primaryInteractive01)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Full List Views

    @ViewBuilder
    private func allPodcastsView() -> some View {
        if let profile = viewModel.profileData {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(profile.podcasts.enumerated()), id: \.element.id) { index, podcast in
                        podcastRow(podcast)

                        if index < profile.podcasts.count - 1 {
                            ThemedDivider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .background(theme.primaryUi01)
            .navigationTitle(L10n.shareProfileFollowedPodcasts)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { path.removeLast() } label: {
                        Image("nav-back")
                            .renderingMode(.template)
                    }
                    .navThemed()
                }
            }
        }
    }

    @ViewBuilder
    private func allEpisodesView() -> some View {
        if let profile = viewModel.profileData {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(profile.episodes.enumerated()), id: \.element.id) { index, episode in
                        episodeRow(episode)

                        if index < profile.episodes.count - 1 {
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
                    Button { path.removeLast() } label: {
                        Image("nav-back")
                            .renderingMode(.template)
                    }
                    .navThemed()
                }
            }
        }
    }
}

#Preview {
    let vm = SharedProfileViewModel(profileSlug: "dom")
    vm.state = .loaded(SharedProfileViewModel.ProfileData(
        displayName: "Dom",
        photoURL: nil,
        podcasts: [
            .init(id: "1", uuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Only a Game", author: "WBUR", artworkURL: ServerHelper.imageUrl(podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", size: 200)),
            .init(id: "2", uuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "The Daily", author: "The New York Times", artworkURL: ServerHelper.imageUrl(podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", size: 200)),
            .init(id: "3", uuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Radiolab", author: "WNYC Studios", artworkURL: ServerHelper.imageUrl(podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", size: 200)),
            .init(id: "4", uuid: "36b645c0-53ee-0131-73c3-723c91aeae46", title: "Serial", author: "Serial Productions", artworkURL: ServerHelper.imageUrl(podcastUuid: "36b645c0-53ee-0131-73c3-723c91aeae46", size: 200)),
        ],
        episodes: [
            .init(id: "1", uuid: "ep-1", podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Episode 1: Origins", podcastTitle: "Only a Game", publishedDate: Date().addingTimeInterval(-86400 * 3), duration: 2400, artworkURL: ServerHelper.imageUrl(podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", size: 200)),
            .init(id: "2", uuid: "ep-2", podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "Switched at Birth", podcastTitle: "The Daily", publishedDate: Date().addingTimeInterval(-86400 * 5), duration: 1800, artworkURL: ServerHelper.imageUrl(podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", size: 200)),
            .init(id: "3", uuid: "ep-3", podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Comedy", podcastTitle: "Radiolab", publishedDate: Date().addingTimeInterval(-86400 * 7), duration: 3600, artworkURL: ServerHelper.imageUrl(podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", size: 200)),
        ]
    ))
    return SharedProfileView(viewModel: vm)
        .setupDefaultEnvironment()
}
