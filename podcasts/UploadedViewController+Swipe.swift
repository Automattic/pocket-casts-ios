import Foundation
import PocketCastsDataModel

extension UploadedViewController: SwipeHandler {
    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isMultiSelectEnabled == false, let episode = uploadedEpisodes[safe: indexPath.row] else { return nil }
        return SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isMultiSelectEnabled == false, let episode = uploadedEpisodes[safe: indexPath.row] else { return nil }
        return SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "files"
    }

    var swipeSourceType: SwipeSourceType {
        .uploaded
    }

    func actionPerformed(willBeRemoved: Bool) {
        reloadLocalFiles()
    }

    func deleteRequested(uuid: String) {
        if let episode = DataManager.sharedManager.findUserEpisode(uuid: uuid) {
            showDeleteConfirmation(userEpisode: episode)
        }
    }

    func archivingRemovesFromList() -> Bool {
        true
    }

    func share(episode: Episode, at: IndexPath) { }

    func addToManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) { }

    func removeFromManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) { }
}
