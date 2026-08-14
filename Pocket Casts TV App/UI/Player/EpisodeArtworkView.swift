import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

@Observable
@MainActor
class EpisodeArtworkViewModel {

    private let artworkManager: EpisodeArtwork
    private let imageManager: ImageManager
    private let placeholderResource: ImageResource
    private let size: PodcastThumbnailSize

    let episode: BaseEpisode

    private(set) var image: UIImage?

    let showEpisodeNotesImage: Bool

    init(episode: BaseEpisode, placeholder: ImageResource = .pcLogo, size: PodcastThumbnailSize = .page, showEpisodeNotesImage: Bool = true, imageManager: ImageManager = .sharedManager) {
        self.episode = episode
        self.placeholderResource = placeholder
        self.imageManager = imageManager
        self.artworkManager = EpisodeArtwork(imageManager: imageManager)
        self.size = size
        self.showEpisodeNotesImage = showEpisodeNotesImage
    }

    func load() async {
        self.image = UIImage(resource: placeholderResource)

        if let podcastImage = await imageManager.imageForEpisode(episode, size: size) {
            image = podcastImage
        }

        if showEpisodeNotesImage, let podcastEpisode = episode as? Episode,
           let episodeImage = await artworkManager.artworkFromShowNotes(podcastUuid: podcastEpisode.podcastUuid, episodeUuid: podcastEpisode.uuid) {
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
