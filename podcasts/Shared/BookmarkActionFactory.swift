import SwiftUI

struct BookmarkActionConfig {
    let showShare: Bool
    let showEdit: Bool
    let onShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
}

func makeBookmarkActions<Style: ActionBarStyle>(_ cfg: BookmarkActionConfig) -> [ActionBarView<Style>.Action] {
    [
        .init(imageName: "podcast-share", title: L10n.share, visible: cfg.showShare, action: cfg.onShare),
        .init(imageName: "folder-edit", title: L10n.edit, visible: cfg.showEdit, action: cfg.onEdit),
        .init(imageName: "delete", title: L10n.delete, action: cfg.onDelete)
    ]
}
