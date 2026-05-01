import SwiftUI
import AVKit

struct EpisodePlayerView: UIViewControllerRepresentable {
    let episode: MockEpisode
    var podcastTitle: String?
    var podcastDescription: String?

    private static let sampleURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: Self.sampleURL)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.player?.currentItem?.externalMetadata = createMetadataItems()
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
