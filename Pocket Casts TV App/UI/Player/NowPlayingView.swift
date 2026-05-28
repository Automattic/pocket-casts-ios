import SwiftUI
import AVKit
import PocketCastsDataModel

struct NowPlayingView: UIViewControllerRepresentable {
    @State private var model = NowPlayingViewModel()
    @State private var isTransportBarVisible = true

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.allowedSubtitleOptionLanguages = []
        controller.delegate = context.coordinator
        model.load()
        addOverlay(to: controller)
        return controller
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isTransportBarVisible: $isTransportBarVisible)
    }

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        @Binding var isTransportBarVisible: Bool

        init(isTransportBarVisible: Binding<Bool>) {
            self._isTransportBarVisible = isTransportBarVisible
        }

        func playerViewController(_ playerViewController: AVPlayerViewController, willTransitionToVisibilityOfTransportBar visible: Bool, with coordinator: any AVPlayerViewControllerAnimationCoordinator) {
            DispatchQueue.main.async { [weak self] in
                self?.isTransportBarVisible = visible
            }
        }
    }

    private func addOverlay(to controller: AVPlayerViewController) {
        guard let contentOverlayView = controller.contentOverlayView else {
            return
        }

        let overlayHostingController = UIHostingController(rootView: MediaOverlayView(model: model, isTransportBarVisible: $model.isLoading))

        guard let overlayView = overlayHostingController.view else {
            return
        }
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        controller.addChild(overlayHostingController)
        contentOverlayView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor),
            overlayView.leftAnchor.constraint(equalTo: contentOverlayView.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: contentOverlayView.rightAnchor)
        ])

        overlayHostingController.didMove(toParent: controller)
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != model.player {
            uiViewController.player = model.player
        }
        uiViewController.player?.currentItem?.externalMetadata = createMetadataItems()
        uiViewController.transportBarCustomMenuItems = [
            makePlaybackSpeedMenu(),
            makePlaybackEffectsMenu()
        ]
        // Suppress AVKit's system loading spinner while the player is still
        // preparing. Hiding playback controls also hides the spinner that
        // lives in the same transport overlay; our branded loading UI in
        // `MediaOverlayView` takes over during this window.
        let shouldShowControls = !model.isLoading
        if uiViewController.showsPlaybackControls != shouldShowControls {
            uiViewController.showsPlaybackControls = shouldShowControls
        }
    }

    private func createMetadataItems() -> [AVMetadataItem] {
        var items = [
            makeMetadataItem(.commonIdentifierTitle, value: model.displayTitle),
            makeMetadataItem(.iTunesMetadataTrackSubTitle, value: model.displaySubTitle),
            makeMetadataItem(.commonIdentifierDescription, value: model.displayTitle)
        ]

        if let imageData = model.displayImageData {
            items.append(makeMetadataItem(.commonIdentifierArtwork, value: imageData))
        }

        return items
    }

    private func makePlaybackSpeedMenu() -> UIMenu {
        let speeds = Array(stride(from: 1.0, through: 3.0, by: 0.1))
        let actions = speeds.map { speed in
            UIAction(
                title: String(format: "%.1fx", speed),
                state: speed == model.playbackSpeed ? .on : .off
            ) { action in
                model.playbackSpeed = speed
                if let menu = action.sender as? UIMenu {
                    menu.children.compactMap { $0 as? UIAction }.forEach { $0.state = .off }
                }
                action.state = .on
                ToastManager.shared.show(L10n.tvPlayerPlaybackSpeedSet(String(format: "%.1fx", speed)))
            }
        }
        return UIMenu(
            title: L10n.tvPlayerPlaybackSpeed,
            image: UIImage(systemName: "gauge.with.dots.needle.33percent"),
            children: [UIMenu(title: "", options: [.displayInline, .singleSelection], children: actions)]
        )
    }

    private func makePlaybackEffectsMenu() -> UIMenu {
        let volumeBoostOff = UIAction(title: L10n.off, state: model.volumeBoost ? .off : .on) { _ in
            ToastManager.shared.show(L10n.tvPlayerVolumeBoostOff)
            model.volumeBoost = false
        }
        let volumeBoostOn = UIAction(title: L10n.on, state: model.volumeBoost ? .on : .off) { _ in
            ToastManager.shared.show(L10n.tvPlayerVolumeBoostOn)
            model.volumeBoost = true
        }
        let volumeBoostSection = UIMenu(
            title: L10n.tvPlayerVolumeBoost,
            options: [.displayInline, .singleSelection],
            children: [volumeBoostOff, volumeBoostOn]
        )

        let trimActions = TrimSilenceAmount.allCases.map { option in
            UIAction(title: option.description, state: model.trimSilence == option ? .on : .off) { _ in
                ToastManager.shared.show(L10n.tvPlayerTrimSilenceSet(option.description))
            }
        }
        let trimSection = UIMenu(
            title: L10n.tvPlayerTrimSilence,
            options: [.displayInline, .singleSelection],
            children: trimActions
        )

        return UIMenu(
            title: L10n.tvPlayerPlaybackEffects,
            image: UIImage(systemName: "speaker.wave.3"),
            children: [volumeBoostSection, trimSection]
        )
    }

    private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
