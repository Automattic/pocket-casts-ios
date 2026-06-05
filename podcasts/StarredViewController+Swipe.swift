import Foundation
import PocketCastsDataModel

extension StarredViewController: SwipeHandler {
    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let episode = episodes[safe: indexPath.row]?.episode, !isMultiSelectEnabled else { return nil }
        return SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let episode = episodes[safe: indexPath.row]?.episode, !isMultiSelectEnabled else { return nil }
        return SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    // MARK: - Swipe Handler

    var swipeSource: String {
        "starred"
    }

    var swipeSourceType: SwipeSourceType {
        .starred
    }

    func archivingRemovesFromList() -> Bool {
        false
    }

    func actionPerformed(willBeRemoved: Bool) {
        refreshEpisodesFromDatabase(animated: true)
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func share(episode: Episode, at indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: starredTable, at: indexPath)
    }

    func addToManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) {
        NavigationManager.sharedManager.navigateTo(
            NavigationManager.manualPlaylistsChooserKey,
            data: [
                NavigationManager.manualPlaylistsChooserEpisodeKey: episode
            ]
        )
    }

    func removeFromManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) { }
}
