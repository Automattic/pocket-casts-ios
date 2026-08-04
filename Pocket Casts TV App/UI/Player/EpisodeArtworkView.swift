import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

@Observable
@MainActor
class EpisodeArtworkViewModel {

    private let artworkManager: EpisodeArtwork
    private let imageManager: ImageManager
    private let placeholderResource: ImageResource

    let episode: BaseEpisode

    var image: UIImage?

    init(episode: BaseEpisode, placeholder: ImageResource = .pcLogo, imageManager: ImageManager = .sharedManager) {
        self.episode = episode
        self.placeholderResource = placeholder
        self.imageManager = imageManager
        self.artworkManager = EpisodeArtwork(imageManager: imageManager)
    }

    func load() async {
        self.image = UIImage(resource: placeholderResource)

        if let podcastImage = await imageManager.imageForEpisode(episode, size: .page) {
            image = podcastImage
        }

        if let podcastEpisode = episode as? Episode,
           let episodeImage = await artworkManager.loadArtworkFromShowNotes(podcastUuid: podcastEpisode.podcastUuid, episodeUuid: podcastEpisode.uuid) {
            image = episodeImage
        }
    }
}

struct EpisodeArtworkView: View {

    @State var model: EpisodeArtworkViewModel

    var body: some View {
        ZStack {
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }.task {
            await model.load()
        }
    }
}
