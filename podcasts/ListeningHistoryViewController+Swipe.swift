import Foundation
import PocketCastsDataModel
import SwipeCellKit

extension ListeningHistoryViewController: SwipeTableViewCellDelegate, SwipeHandler {
    // MARK: - SwipeTableViewCellDelegate

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard !isMultiSelectEnabled, let episode = episodes[safe: indexPath.section]?.elements[safe: indexPath.row]?.episode else { return nil }

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
        "listening_history"
    }

    func archivingRemovesFromList() -> Bool {
        false
    }

    func actionPerformed(willBeRemoved: Bool) {
        refreshEpisodes(animated: true)
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func share(episode: Episode, in indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: listeningHistoryTable, at: indexPath)
    }
}
