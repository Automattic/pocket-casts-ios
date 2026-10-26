import Foundation
import PocketCastsDataModel
import SwiftUI
import UIKit

extension PodcastViewController: SwipeHandler {
    // MARK: - Swipe Actions

    func episodeSwipeActionsConfiguration(for edge: HorizontalEdge, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isMultiSelectEnabled, indexPath.section == PodcastViewController.allEpisodesSection, let episode = episodeAtIndexPath(indexPath) else { return nil }

        let tableView = tableView()
        switch edge {
        case .leading:
            return SwipeActionsHelper.createLeftActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
        case .trailing:
            return SwipeActionsHelper.createRightActionsForEpisode(episode, tableView: tableView, indexPath: indexPath, swipeHandler: self).swipeActions()
        }
    }

    // MARK: - SwipeActionsHandler

    var swipeSource: String {
        "podcast_details"
    }

    var swipeSourceType: SwipeSourceType {
        .podcast
    }

    func archivingRemovesFromList() -> Bool {
        !(podcast?.showArchived ?? false)
    }

    func actionPerformed(willBeRemoved: Bool) {
        guard let podcast else { return }

        loadLocalEpisodes(podcast: podcast, animated: true)
    }

    func deleteRequested(uuid: String) {} // we don't support this one

    func share(episode: Episode, at indexPath: IndexPath) {
        SharingHelper.shared.shareLinkTo(episode: episode, fromController: self, fromTableView: tableView(), at: indexPath)
    }

    func addToManualPlaylist(episode: Episode, at: IndexPath) {
        NavigationManager.shared.navigateTo(
            NavigationManager.manualPlaylistsChooserKey,
            data: [
                NavigationManager.manualPlaylistsChooserEpisodeKey: episode
            ]
        )
    }

    func removeFromManualPlaylist(episode: PocketCastsDataModel.Episode, at: IndexPath) { }
}
