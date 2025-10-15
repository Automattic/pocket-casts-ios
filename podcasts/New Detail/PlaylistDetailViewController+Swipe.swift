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

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "playlists"
    }

    var swipeSourceType: SwipeSourceType {
        viewModel.isManualPlaylist ? .manualPlaylistDetail : .smartPlaylistDetail
    }

    func actionPerformed(willBeRemoved: Bool) {
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
}
