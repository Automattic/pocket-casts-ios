import SwiftUI
import AVKit
import PocketCastsDataModel

struct NowPlayingView: UIViewControllerRepresentable {
    @State var model = NowPlayingViewModel()

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.transportBarCustomMenuItems = [
            makePlaybackSpeedMenu(player: model.player),
            makePlaybackEffectsMenu()
        ]
        controller.allowedSubtitleOptionLanguages = []
        TVToast.shared.configure(with: controller.contentOverlayView)
        model.load()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = model.player
        uiViewController.player?.currentItem?.externalMetadata = createMetadataItems()
    }

    private func createMetadataItems() -> [AVMetadataItem] {
        var items = [
            makeMetadataItem(.commonIdentifierTitle, value: model.displayTitle),
            makeMetadataItem(.iTunesMetadataTrackSubTitle, value: model.displaySubTitle),
            makeMetadataItem(.commonIdentifierDescription, value: model.displayInfo)
        ]

        if let imageData = model.displayImageData {
            items.append(makeMetadataItem(.commonIdentifierArtwork, value: imageData))
        }

        return items
    }

    private func makePlaybackSpeedMenu(player: AVPlayer?) -> UIMenu {
        let speeds = Array(stride(from: 1.0, through: 3.0, by: 0.1))
        let actions = speeds.map { speed in
            UIAction(
                title: String(format: "%.1fx", speed),
                state: speed == model.playbackSpeed ? .on : .off
            ) { action in
                model.setPlaybackSpeed(speed: speed)
                if let menu = action.sender as? UIMenu {
                    menu.children.compactMap { $0 as? UIAction }.forEach { $0.state = .off }
                }
                action.state = .on
                TVToast.shared.show(L10n.tvPlayerPlaybackSpeedSet(String(format: "%.1fx", speed)))
            }
        }
        return UIMenu(
            title: L10n.tvPlayerPlaybackSpeed,
            image: UIImage(systemName: "gauge.with.dots.needle.33percent"),
            children: [UIMenu(title: "", options: [.displayInline, .singleSelection], children: actions)]
        )
    }

    private func makePlaybackEffectsMenu() -> UIMenu {
        let volumeBoostOff = UIAction(title: L10n.off, state: .on) { _ in
            TVToast.shared.show(L10n.tvPlayerVolumeBoostOff)
        }
        let volumeBoostOn = UIAction(title: L10n.on, state: .off) { _ in
            TVToast.shared.show(L10n.tvPlayerVolumeBoostOn)
        }
        let volumeBoostSection = UIMenu(
            title: L10n.tvPlayerVolumeBoost,
            options: [.displayInline, .singleSelection],
            children: [volumeBoostOff, volumeBoostOn]
        )

        let trimOptions: [(String, UIAction.State)] = [
            (L10n.tvPlayerTrimSilenceOff, .on),
            (L10n.tvPlayerTrimSilenceMild, .off),
            (L10n.tvPlayerTrimSilenceMedium, .off),
            (L10n.tvPlayerTrimSilenceMadMax, .off)
        ]
        let trimActions = trimOptions.map { title, state in
            UIAction(title: title, state: state) { _ in
                TVToast.shared.show(L10n.tvPlayerTrimSilenceSet(title))
            }
        }
        let trimSection = UIMenu(
            title: L10n.tvPlayerTrimSilence,
            options: [.displayInline, .singleSelection],
            children: trimActions
        )

        return UIMenu(
            title: L10n.tvPlayerVolumeBoost,
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
