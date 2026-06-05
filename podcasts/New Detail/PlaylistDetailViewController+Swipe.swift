import PocketCastsDataModel
import UIKit

extension PlaylistDetailViewController: SwipeHandler {
    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isMultiSelectEnabled, let episode = viewModel.episodes[safe: indexPath.row]?.episode else { return nil }
        return SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isMultiSelectEnabled, let episode = viewModel.episodes[safe: indexPath.row]?.episode else { return nil }
        return SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        reloader.pause(for: .seconds(8)) // Adding a timeout just in case calling `resume` for whatever reason
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        reloader.resume(after: .seconds(1))
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "filters"
    }

    var swipeSourceType: SwipeSourceType {
        viewModel.isManualPlaylist ? .manualPlaylistDetail : .smartPlaylistDetail
    }

    func actionPerformed(willBeRemoved: Bool) {
        reloader.resume(after: .seconds(1))
        if willBeRemoved {
            viewModel.reloadEpisodeList()
        }
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func archivingRemovesFromList() -> Bool {
        true
    }

    func share(episode: Episode, at indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: tableView, at: indexPath)
    }

    func addToManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) {
        NavigationManager.sharedManager.navigateTo(
            NavigationManager.manualPlaylistsChooserKey,
            data: [
                NavigationManager.manualPlaylistsChooserEpisodeKey: episode
            ]
        )
    }

    func removeFromManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) {
        track(episode: episode, added: false, to: viewModel.playlist, source: "swipe_remove")

        viewModel.delete(episodes: [episode.uuid])
        viewModel.reloadEpisodeList()
    }
}
