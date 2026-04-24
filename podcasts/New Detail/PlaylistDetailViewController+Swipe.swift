import PocketCastsDataModel
import SwipeCellKit

extension PlaylistDetailViewController: SwipeTableViewCellDelegate, SwipeHandler {
    // MARK: - SwipeTableViewCellDelegate

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard !isMultiSelectEnabled, let episode = viewModel.episodes[safe: indexPath.row]?.episode else { return nil }

        switch orientation {
        case .left:
            let actions = SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self)
            return actions.swipeKitActions()
        case .right:
            let actions = SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self)
            return actions.swipeKitActions()
        }
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()

        switch orientation {
        case .left:
            options.expansionStyle = .selection
        case .right:
            options.expansionStyle = .destructive(automaticallyDelete: false)
        }

        return options
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        reloader.pause(for: .seconds(8)) // Adding a timeout just in case
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
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
