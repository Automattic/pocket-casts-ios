import PocketCastsDataModel
import SwiftUI

/// The actions of the bookmarks multi select action bar. What's offered depends on the selection.
@MainActor func makeBookmarkActions<Style: ActionBarStyle>(viewModel: BookmarkListViewModel) -> [ActionBarView<Style>.Action] {
    let selected = viewModel.selectedItems
    let isSingleSelection = selected.count == 1
    let canShare = isSingleSelection && selected.first?.episode is Episode

    return [
        .init(imageName: "podcast-share", title: L10n.share, visible: canShare) { viewModel.shareSelectedBookmarks() },
        .init(imageName: "folder-edit", title: L10n.edit, visible: isSingleSelection) { viewModel.editSelectedBookmarks() },
        .init(imageName: "delete", title: L10n.delete) { viewModel.deleteSelectedBookmarks() }
    ]
}

/// A swipe action of a bookmark row, rendered by SwiftUI in the bookmarks list and by UIKit in the
/// podcast page's table
struct BookmarkSwipeAction: Identifiable {
    let imageName: String
    let title: String
    let tint: Color
    let isDestructive: Bool
    let handler: () -> Void

    var id: String { imageName }
}

/// The swipe actions of a single bookmark row. There are none while the list is multi selecting.
@MainActor func makeBookmarkSwipeActions<Style: BookmarksStyle>(for bookmark: Bookmark,
                                                                edge: HorizontalEdge,
                                                                viewModel: BookmarkListViewModel,
                                                                style: Style) -> [BookmarkSwipeAction] {
    guard !viewModel.isMultiSelecting else { return [] }

    switch edge {
    case .leading:
        guard viewModel.canShare(bookmark) else { return [] }

        return [
            .init(imageName: "podcast-share", title: L10n.share, tint: style.shareSwipeTint, isDestructive: false) {
                viewModel.shareTapped(bookmark)
            }
        ]
    case .trailing:
        return [
            .init(imageName: "delete", title: L10n.delete, tint: style.deleteSwipeTint, isDestructive: true) {
                viewModel.deleteTapped(bookmark)
            }
        ]
    }
}
