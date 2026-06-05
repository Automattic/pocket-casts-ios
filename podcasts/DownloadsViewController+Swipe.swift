import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension DownloadsViewController: SwipeHandler {
    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isMultiSelectEnabled, let episode = episodeAtIndexPath(indexPath) else { return nil }
        return SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isMultiSelectEnabled, let episode = episodeAtIndexPath(indexPath) else { return nil }
        return SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "downloads"
    }

    var swipeSourceType: SwipeSourceType {
        .downloads
    }

    func archivingRemovesFromList() -> Bool {
        true
    }

    func actionPerformed(willBeRemoved: Bool) {
        if willBeRemoved {
            reloadEpisodes()
        }
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func share(episode: Episode, at indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: downloadsTable, at: indexPath)
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
