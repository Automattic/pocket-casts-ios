import SwiftUI
import AVKit

struct EpisodePlayerView: UIViewControllerRepresentable {
    let episode: MockEpisode
    var podcastTitle: String?
    var podcastDescription: String?

    private static let sampleURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: Self.sampleURL)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.player?.currentItem?.externalMetadata = createMetadataItems()
        controller.transportBarCustomMenuItems = [
            makePlaybackSpeedMenu(player: player),
            makePlaybackEffectsMenu()
        ]
        controller.allowedSubtitleOptionLanguages = []
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    private func createMetadataItems() -> [AVMetadataItem] {
        var items = [
            makeMetadataItem(.commonIdentifierTitle, value: episode.title)
        ]
        if let podcastTitle {
            items.append(makeMetadataItem(.iTunesMetadataTrackSubTitle, value: podcastTitle))
        }
        if let imageData = UIImage(named: episode.image)?.pngData() {
            items.append(makeMetadataItem(.commonIdentifierArtwork, value: imageData))
        }
        if let podcastDescription {
            items.append(makeMetadataItem(.commonIdentifierDescription, value: podcastDescription))
        }
        return items
    }

    private func makePlaybackSpeedMenu(player: AVPlayer) -> UIMenu {
        let speeds = stride(from: 1.0, through: 3.0, by: 0.1).map { $0 }
        let actions = speeds.map { speed in
            UIAction(
                title: String(format: "%.1fx", speed),
                state: speed == 1.0 ? .on : .off
            ) { action in
                player.rate = Float(speed)
                if let menu = action.sender as? UIMenu {
                    menu.children.compactMap { $0 as? UIAction }.forEach { $0.state = .off }
                }
                action.state = .on
            }
        }
        return UIMenu(
            title: L10n.tvPlayerPlaybackSpeed,
            image: UIImage(systemName: "gauge.with.dots.needle.33percent"),
            children: [UIMenu(title: "", options: [.displayInline, .singleSelection], children: actions)]
        )
    }

    private func makePlaybackEffectsMenu() -> UIMenu {
        let volumeBoostAction = UIAction(
            title: L10n.tvPlayerVolumeBoost,
            image: UIImage(systemName: "speaker.wave.3"),
            state: .off
        ) { action in
            action.state = action.state == .off ? .on : .off
        }

        let trimOptions: [(String, UIAction.State)] = [
            (L10n.tvPlayerTrimSilenceOff, .on),
            (L10n.tvPlayerTrimSilenceMild, .off),
            (L10n.tvPlayerTrimSilenceMedium, .off),
            (L10n.tvPlayerTrimSilenceMadMax, .off)
        ]
        let trimActions = trimOptions.map { title, state in
            UIAction(title: title, state: state) { _ in }
        }
        let trimSubmenu = UIMenu(
            title: L10n.tvPlayerTrimSilence,
            options: [.displayInline, .singleSelection],
            children: trimActions
        )

        return UIMenu(
            title: L10n.tvPlayerPlaybackEffects,
            image: UIImage(systemName: "slider.horizontal.3"),
            children: [volumeBoostAction, trimSubmenu]
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

struct EpisodePlayerButton: View {
    let episode: MockEpisode
    var podcastTitle: String?
    var podcastDescription: String?
    @State private var isPlaying = false

    var body: some View {
        Button {
            isPlaying = true
        } label: {
            EpisodeRow(episode: episode)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .fullScreenCover(isPresented: $isPlaying) {
            EpisodePlayerView(
                episode: episode,
                podcastTitle: podcastTitle,
                podcastDescription: podcastDescription
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    EpisodePlayerButton(
        episode: MockData.makePodcasts().first!.episodes.first!,
        podcastTitle: "The Daily"
    )
}
