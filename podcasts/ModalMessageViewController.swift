class ModalMessageViewController {
    static func episodeUnavailableAlert(removeAction: (() -> Void)? = nil) -> ModalMessageView {
        return ModalMessageView(
            icon: "bang-circle-ol",
            title: L10n.episodeUnavailableTitle,
            message: L10n.episodeUnavailableMessage,
            destructive: false,
            actionTitle: L10n.removeFromPlaylist
        ) {
            removeAction?()
        }
    }
}
