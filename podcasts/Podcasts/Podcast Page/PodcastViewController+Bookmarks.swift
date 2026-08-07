import UIKit

extension PodcastViewController {
    func setupBookmarkList() {
        guard let podcast, bookmarkList == nil else { return }

        bookmarkList = BookmarkListController(podcast: podcast, tableView: episodesTable, delegate: self)
    }
}

// MARK: - BookmarkListControllerDelegate

extension PodcastViewController: BookmarkListControllerDelegate {
    var isBookmarkListDisplayed: Bool {
        currentViewMode == .bookmarks
    }

    func bookmarkListControllerDidChangeSearchVisibility(_ controller: BookmarkListController) {
        reloadData()
    }

    func bookmarkListControllerDidChangeMultiSelection(_ controller: BookmarkListController) {
        if isMultiSelectEnabled != controller.viewModel.isMultiSelecting {
            isMultiSelectEnabled = controller.viewModel.isMultiSelecting
        }

        updateSelectAllBtn()
    }
}
