import Foundation
import PocketCastsDataModel
import SwipeCellKit

extension UploadedViewController: SwipeTableViewCellDelegate, SwipeHandler {
    // MARK: - SwipeTableViewCellDelegate

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard isMultiSelectEnabled == false, let episode = uploadedEpisodes[safe: indexPath.row] else { return nil }

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
        options.expansionStyle = .selection

        return options
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "files"
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

    func share(episode: Episode, in: IndexPath) { }
}
