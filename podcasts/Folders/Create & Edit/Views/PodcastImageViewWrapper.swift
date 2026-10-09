import SwiftUI

struct PodcastImageViewWrapper: UIViewRepresentable {
    let podcastUUID: String
    let size: PodcastThumbnailSize
    var placeholder: PodcastImageView.Placeholder = .noArtwork

    func makeUIView(context: Context) -> PodcastImageView {
        PodcastImageView()
    }

    func updateUIView(_ podcastImageView: PodcastImageView, context: Context) {
        podcastImageView.placeholder = placeholder
        podcastImageView.setPodcast(uuid: podcastUUID, size: size)
    }
}
