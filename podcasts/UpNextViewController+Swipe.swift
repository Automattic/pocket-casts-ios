import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwipeCellKit

extension UpNextViewController: SwipeTableViewCellDelegate {
    func swipeCurrentlyAllowed() -> Bool {
        return isReorderInProgress == false
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        switch orientation {
        case .left:
            let moveToTopAction = SwipeAction(style: .default, title: nil) { [weak self] _, indexPath in
                guard let self = self, let episode = PlaybackManager.shared.queue.episodeAt(index: indexPath.row) else { return }

                Analytics.track(.episodeSwipeActionPerformed, properties: ["action": "up_next_move_up", "source": "up_next"])

                PlaybackManager.shared.queue.move(episode: episode, to: 0, fireNotification: false)
                self.moveRow(at: indexPath, to: IndexPath(row: 0, section: indexPath.section), in: tableView)
            }
            moveToTopAction.image = UIImage(named: "upnext-movetotop")
            moveToTopAction.backgroundColor = ThemeColor.support04()
            moveToTopAction.accessibilityLabel = L10n.moveToTop
            moveToTopAction.hidesWhenSelected = true
            let moveToBottomAction = SwipeAction(style: .default, title: nil) { [weak self] _, indexPath in
                guard let self = self, let episode = PlaybackManager.shared.queue.episodeAt(index: indexPath.row) else { return }

                let queueCount = PlaybackManager.shared.queue.upNextCount()
                PlaybackManager.shared.queue.move(episode: episode, to: queueCount - 1, fireNotification: false)
                self.moveRow(at: indexPath, to: IndexPath(row: queueCount - 1, section: indexPath.section), in: tableView)
                Analytics.track(.episodeSwipeActionPerformed, properties: ["action": "up_next_move_down", "source": "up_next"])
            }
            moveToBottomAction.image = UIImage(named: "upnext-movetobottom")
            moveToBottomAction.backgroundColor = ThemeColor.support03()
            moveToBottomAction.accessibilityLabel = L10n.moveToBottom
            moveToBottomAction.hidesWhenSelected = true
            return [moveToTopAction, moveToBottomAction]
        case .right:
            let deleteAction = SwipeAction(style: .destructive, title: nil) { [weak self] _, indexPath in
                guard let self = self, let episode = PlaybackManager.shared.queue.episodeAt(index: indexPath.row) else { return }

                self.changedViaSwipeToRemove = true
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
                Analytics.track(.episodeSwipeActionPerformed, properties: ["action": "delete", "source": "up_next"])
                let remainingEpisodes = PlaybackManager.shared.queue.upNextCount()
                if remainingEpisodes > 0 {
                    do {
                        try SJCommonUtils.catchException {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    } catch {
                        FileLog.shared.addMessage("Caught Objective-C exception while trying to remove an Up Next row by swiping, reloading table instead")
                        tableView.reloadData()
                    }
                } else {
                    tableView.reloadData() // if they delete the very last episode, reload the table to get the empty up next cell
                }
                self.changedViaSwipeToRemove = false
            }

            // customize the action appearance
            deleteAction.image = UIImage(named: "episode-removenext")
            deleteAction.backgroundColor = ThemeColor.support05(for: themeOverride)
            deleteAction.accessibilityLabel = L10n.removeFromUpNext
            return [deleteAction]
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

    private func moveRow(at: IndexPath, to: IndexPath, in tableView: UITableView) {
        do {
            try SJCommonUtils.catchException {
                tableView.moveRow(at: at, to: to)
            }
        } catch {
            FileLog.shared.addMessage("Caught Objective-C exception while trying to move an Up Next row, reloading table instead")
            tableView.reloadData()
        }
    }
}
