import Foundation
import PocketCastsDataModel
import SwipeCellKit

extension PodcastViewController: SwipeTableViewCellDelegate, SwipeHandler {
    // MARK: - SwipeTableViewCellDelegate

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard !isMultiSelectEnabled, indexPath.section == PodcastViewController.allEpisodesSection, let episode = episodeAtIndexPath(indexPath) else { return nil }

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
        // Defer notification-driven reloads so they don't tear down the cell
        // mid-animation when an action fires (e.g. Add to Up Next). The timeout
        // is a safety net in case `didEndEditingRowAt` is never delivered.
        reloader.pause(for: .seconds(8))
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        reloader.resume(after: .seconds(1))
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "podcast_details"
    }

    var swipeSourceType: SwipeSourceType {
        .podcast
    }

    func archivingRemovesFromList() -> Bool {
        !(podcast?.shouldShowArchived ?? false)
    }

    func actionPerformed(willBeRemoved: Bool) {
        // Let the swipe close/bounce animation finish before reloads resume.
        reloader.resume(after: .seconds(1))

        // Only the destructive actions (e.g. archive) need an immediate reload
        // to drop the row. Up Next add/remove keeps the row and the cell
        // refreshes its own indicator (see EpisodeCell), so no reload here.
        if willBeRemoved, let podcast {
            loadLocalEpisodes(podcast: podcast, animated: true)
        }
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func share(episode: Episode, at indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: tableView(), at: indexPath)
    }

    func addToManualPlaylist(episode: Episode, at: IndexPath) {
        NavigationManager.sharedManager.navigateTo(
            NavigationManager.manualPlaylistsChooserKey,
            data: [
                NavigationManager.manualPlaylistsChooserEpisodeKey: episode
            ]
        )
    }

    func removeFromManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) { }
}
