import Foundation
import PocketCastsDataModel
import PocketCastsServer

@Observable
class NowPlayingViewModel: Identifiable {

    let playbackManager: PlaybackManager

    var imageData: Data?
    var player: AVPlayer?
    var episode: BaseEpisode?

    init(playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.playbackManager = playbackManager
    }

    func load() {
        episode = playbackManager.currentEpisode()
        loadEpisodeArtwork()
    }

    func loadEpisodeArtwork() {
        Task.detached { [weak self] in
            let data = await self?.loadEpisodeArtworkData()
            await MainActor.run { [weak self] in
                self?.imageData = data
            }
        }
    }

    var displayTitle: String {
        return episode?.displayableTitle() ?? ""
    }

    var displaySubTitle: String {
        return episode?.subTitle() ?? ""
    }

    var displayInfo: String {
        return episode?.displayableInfo() ?? ""
    }

    var displayDate: String {
        return episode?.shortPublishedDate() ?? ""
    }

    var displayDuration: String {
        return episode?.displayableDuration ?? ""
    }

    var displayImageData: Data? {
        return imageData
    }

    private func loadEpisodeArtworkData() async -> Data? {
        guard let podcastUuid = episode?.parentIdentifier() else {
            return nil
        }

        let imageUrl = ServerHelper.image(podcastUuid: podcastUuid, size: 340)
        guard let url = URL(string: imageUrl),
              let (data, _) = try? await URLSession.shared.data(for: URLRequest.init(url: url)),
              let uiImage = UIImage(data: data)
        else {
            return nil
        }
        return uiImage.pngData()
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }
}
