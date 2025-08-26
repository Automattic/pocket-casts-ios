import SwiftUI

extension PlaylistDetailViewController {
    func reloadEmptyState() {
        if viewModel.isSearching { return }

        var config: UIContentConfiguration?

        tableView.isHidden = viewModel.episodes.isEmpty

        if viewModel.episodes.isEmpty {
            // Empty State when playlists is empty
            let title = L10n.episodeFilterNoEpisodesTitle
            let message = L10n.episodeFilterNoEpisodesMsg
            config = ContentUnavailableConfiguration.emptyState(
                title: title,
                message: message,
                icon: {
                    Image("empty-playlist-info")
                },
                actions: [
                .init(
                    title: L10n.playlistSmartRulesTitle,
                    action: { [weak self] in
                    self?.editPlaylist()
                    }
                )
            ])
        }
        set(configuration: config)
    }

    func set(configuration: UIContentConfiguration?) {
        self.setContentUnavailableConfiguration(configuration)
    }
}
