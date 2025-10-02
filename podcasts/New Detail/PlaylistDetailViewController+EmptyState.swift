import SwiftUI

extension PlaylistDetailViewController {
    private var emptyStateTitle: String {
        if viewModel.isManualPlaylist {
            return viewModel.hasSubscribedPodcasts ? L10n.playlistManualEmptyStateTitle : L10n.playlistManualEmptyStateTitleNoPodcasts
        }
        return L10n.episodeFilterNoEpisodesTitle
    }

    private var emptyStateDescription: String? {
        if viewModel.isManualPlaylist {
            return viewModel.hasSubscribedPodcasts ? nil : L10n.playlistManualEmptyStateSubtitleNoPodcasts
        }
        return L10n.playlistSmartNoEpisodesMsg
    }

    private var emptyStateIcon: Image {
        return viewModel.isManualPlaylist ? Image("playlists_tab") : Image("empty-playlist-info")
    }

    private var emptyStateButtonTitle: String {
        if viewModel.isManualPlaylist {
            return viewModel.hasSubscribedPodcasts ? L10n.playlistManualAddEpisodes : L10n.playlistManualBrowseShowsTitle
        }
        return L10n.playlistSmartRulesTitle
    }

    func reloadEmptyState() {
        if viewModel.isSearching { return }

        var config: UIContentConfiguration?

        tableView.isHidden = viewModel.episodes.isEmpty

        if viewModel.episodes.isEmpty {
            // Empty State when playlists is empty
            config = ContentUnavailableConfiguration.emptyState(
                title: emptyStateTitle,
                message: emptyStateDescription,
                icon: {
                    self.emptyStateIcon
                },
                actions: [
                .init(
                    title: emptyStateButtonTitle,
                    action: { [weak self] in
                        self?.emptyStateAction()
                    }
                )
            ])
        }
        set(configuration: config)
    }

    func set(configuration: UIContentConfiguration?) {
        self.setContentUnavailableConfiguration(configuration)
    }

    private func emptyStateAction() {
        if !viewModel.isManualPlaylist {
            editPlaylist()
            return
        }
        if viewModel.hasSubscribedPodcasts {
            addEpisodes()
            return
        }
        NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey)
    }
}
