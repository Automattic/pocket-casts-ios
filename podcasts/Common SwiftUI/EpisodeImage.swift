import SwiftUI
import PocketCastsDataModel

/// An Image wrapper that will load the image for a `BaseEpisode`
struct EpisodeImage: View {
    private let episode: BaseEpisode
    private let imageManager: ImageManager

    @State private var episodeImage: UIImage? = nil

    init(episode: BaseEpisode, placeholder: UIImage? = nil, imageManager: ImageManager = .sharedManager) {
        self.episode = episode

        let placeholderImage = placeholder ?? imageManager.placeHolderImage(.list)
        _episodeImage = .init(initialValue: placeholderImage)

        self.imageManager = imageManager
    }

    var body: some View {
        Group {
            // Make sure that the loading task is ran even if the placeholder is nil
            if let episodeImage {
                Image(uiImage: episodeImage)
                    .resizable()
            } else {
                Color.clear
            }
        }.task {
            loadImage()
        }
    }

    private func loadImage() {
        imageManager.imageForEpisode(episode, size: .list) { image in
            guard let image else { return }

            self.episodeImage = image
        }
    }
}
