import PocketCastsDataModel
import SwiftUI

/// The actions of the bookmarks multi select action bar. What's offered depends on the selection.
@MainActor func makeBookmarkActions<Style: ActionBarStyle>(viewModel: BookmarkListViewModel) -> [ActionBarView<Style>.Action] {
    let isSingleSelection = viewModel.numberOfSelectedItems == 1
    let canShare = isSingleSelection && viewModel.selectedItems.first?.episode is Episode

    return [
        .init(imageName: "podcast-share", title: L10n.share, visible: canShare) { viewModel.shareSelectedBookmarks() },
        .init(imageName: "folder-edit", title: L10n.edit, visible: isSingleSelection) { viewModel.editSelectedBookmarks() },
        .init(imageName: "delete", title: L10n.delete) { viewModel.deleteSelectedBookmarks() }
    ]
}
