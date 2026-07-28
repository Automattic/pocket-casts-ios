import SwiftUI

struct PodcastImageViewWrapper: UIViewRepresentable {
    let podcastUUID: String
    let size: PodcastThumbnailSize

    func makeUIView(context: Context) -> PodcastImageView {
        PodcastImageView()
    }

    func updateUIView(_ podcastImageView: PodcastImageView, context: Context) {
        podcastImageView.setPodcast(uuid: podcastUUID, size: size)
    }
}
