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
                        if let profile = viewModel.profileData {
                            SharedProfilePodcastsList(
                                podcasts: profile.podcasts,
                                navigateToPodcast: { uuid in navigateToPodcast(uuid: uuid) },
                                goBack: { path.removeLast() }
                            )
                        }
                    case .allEpisodes:
                        if let profile = viewModel.profileData {
                            SharedProfileEpisodeList(
                                episodes: profile.episodes,
                                navigateToEpisode: { uuid, podcastUuid in navigateToEpisode(uuid: uuid, podcastUuid: podcastUuid) },
                                playEpisode: { uuid, podcastUuid in viewModel.playEpisode(uuid: uuid, podcastUuid: podcastUuid) },
                                goBack: { path.removeLast() }
                            )
                        }
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
            VStack(spacing: 0) {
                profileHeader(profile)
                    .padding(.bottom, 24)

                if !profile.podcasts.isEmpty {
                    podcastsSection(profile.podcasts)
                }

                if !profile.episodes.isEmpty {
                    if !profile.podcasts.isEmpty {
                        ThemedDivider()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                    }

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
        VStack(spacing: 8) {
            if let photoURL = profile.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    profilePlaceholder
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                profilePlaceholder
            }

            Text(profile.displayName)
                .font(style: .title3, weight: .bold)
                .foregroundColor(theme.primaryText01)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(.systemGray2))
            )
    }

    // MARK: - Podcasts Section

    @ViewBuilder
    private func podcastsSection(_ podcasts: [SharedProfileViewModel.PodcastInfo]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L10n.shareProfileFollowedPodcasts) {
                path.append(.allPodcasts)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(podcasts.prefix(8)), id: \.id) { podcast in
                        podcastCard(podcast)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func podcastCard(_ podcast: SharedProfileViewModel.PodcastInfo) -> some View {
        let cardWidth: CGFloat = 150

        Button {
            navigateToPodcast(uuid: podcast.uuid)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                PodcastImage(uuid: podcast.uuid, size: .grid)
                    .frame(width: cardWidth, height: cardWidth)
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .overlay(alignment: .bottomTrailing) {
                        SharedProfileSubscribeButton(podcastUuid: podcast.uuid, style: .overlay)
                            .offset(x: -4, y: -4)
                    }
                    .padding(.bottom, 8)

                Text(podcast.title)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(1)
                    .padding(.bottom, 2)

                if let author = podcast.author {
                    Text(author)
                        .font(style: .footnote, weight: .regular)
                        .foregroundColor(theme.primaryText02)
                        .lineLimit(1)
                }
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Episodes Section

    @ViewBuilder
    private func episodesSection(_ episodes: [SharedProfileViewModel.EpisodeInfo]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(L10n.shareProfileRecentEpisodes) {
                path.append(.allEpisodes)
            }

            ForEach(Array(episodes.prefix(3).enumerated()), id: \.element.id) { index, episode in
                SharedProfileEpisodeRow(
                    episode: episode,
                    navigateToEpisode: { navigateToEpisode(uuid: episode.uuid, podcastUuid: episode.podcastUuid) },
                    playEpisode: { viewModel.playEpisode(uuid: episode.uuid, podcastUuid: episode.podcastUuid) }
                )

                if index < min(episodes.count, 3) - 1 {
                    ThemedDivider()
                }
            }
        }
    }

    // MARK: - Navigation

    private func presentOnTop(_ viewController: UIViewController) {
        var topVC = SceneHelper.rootViewController()
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        topVC?.present(viewController, animated: true)
    }

    private func addCloseButton(to viewController: UIViewController) {
        // Force viewDidLoad so PodcastViewController's nav bar setup runs before we override leftBarButtonItem
        _ = viewController.view
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), primaryAction: UIAction { [weak viewController] _ in
            viewController?.dismiss(animated: true)
        })
        viewController.navigationItem.leftBarButtonItem = closeButton
    }

    private func navigateToPodcast(uuid: String) {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
            let podcastVC = PodcastViewController(podcast: podcast)
            let navVC = SJUIUtils.navController(for: podcastVC)
            addCloseButton(to: podcastVC)
            presentOnTop(navVC)
        } else {
            ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: false) { success in
                DispatchQueue.main.async {
                    if success, let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
                        let podcastVC = PodcastViewController(podcast: podcast)
                        let navVC = SJUIUtils.navController(for: podcastVC)
                        addCloseButton(to: podcastVC)
                        presentOnTop(navVC)
                    }
                }
            }
        }
    }

    private func navigateToEpisode(uuid: String, podcastUuid: String) {
        let loadingVC = EpisodeLoadingController(episodeUuid: uuid, podcastUuid: podcastUuid)
        let navVC = SJUIUtils.navController(for: loadingVC)
        addCloseButton(to: loadingVC)
        presentOnTop(navVC)
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
}

#Preview {
    let vm = SharedProfileViewModel(profileSlug: "dom")
    vm.state = .loaded(SharedProfileViewModel.ProfileData(
        displayName: "Dom",
        photoURL: nil,
        podcasts: [
            .init(id: "1", uuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Only a Game", author: "WBUR"),
            .init(id: "2", uuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "The Daily", author: "The New York Times"),
            .init(id: "3", uuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Radiolab", author: "WNYC Studios"),
            .init(id: "4", uuid: "36b645c0-53ee-0131-73c3-723c91aeae46", title: "Serial", author: "Serial Productions"),
        ],
        episodes: [
            .init(id: "1", uuid: "ep-1", podcastUuid: "da3271a0-69e7-0132-d9fd-5f4c86fd3263", title: "Episode 1: Origins", podcastTitle: "Only a Game", publishedDate: Date().addingTimeInterval(-86400 * 3), duration: 2400),
            .init(id: "2", uuid: "ep-2", podcastUuid: "3782b780-0bc5-012e-fb02-00163e46d440", title: "Switched at Birth", podcastTitle: "The Daily", publishedDate: Date().addingTimeInterval(-86400 * 5), duration: 1800),
            .init(id: "3", uuid: "ep-3", podcastUuid: "0d10b550-e227-0133-2e8b-6dc413d6d41d", title: "Comedy", podcastTitle: "Radiolab", publishedDate: Date().addingTimeInterval(-86400 * 7), duration: 3600),
        ]
    ))
    return SharedProfileView(viewModel: vm)
        .setupDefaultEnvironment()
}
