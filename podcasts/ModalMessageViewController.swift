class ModalMessageViewController {
    static func episodeUnavailableAlert(removeAction: (() -> Void)? = nil) -> UIViewController {
        let modalView = ModalMessageView(
            icon: "option-alert",
            title: L10n.episodeUnavailableTitle,
            message: L10n.episodeUnavailableMessage,
            destructive: true,
            actionTitle: L10n.removeFromPlaylist
        ) {
            removeAction?()
        }

        let hostingController = ThemedHostingController(rootView: modalView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        return hostingController
    }
}
