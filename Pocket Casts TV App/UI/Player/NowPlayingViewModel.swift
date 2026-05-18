import Foundation
import PocketCastsDataModel
import PocketCastsServer

@Observable
class NowPlayingViewModel: Identifiable {

    let playbackManager: PlaybackManager

    var displayImage: UIImage?
    var imageData: Data?
    var player: AVPlayer?
    var episode: BaseEpisode?
    var podcast: Podcast?

    init(playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.playbackManager = playbackManager
    }

    func load() {
        episode = playbackManager.currentEpisode()
        podcast = playbackManager.currentPodcast
        player = playbackManager.avPlayer
        loadEpisodeArtwork()
    }

    func loadEpisodeArtwork() {
        Task.detached { [weak self] in
            let image = await self?.loadEpisodeArtworkData()
            await MainActor.run { [weak self] in
                self?.imageData = image?.pngData()
                self?.displayImage = image
                self?.player = self?.playbackManager.avPlayer
            }
        }
    }

    var isVideo: Bool {
        return episode?.videoPodcast() ?? false
    }

    var displayTitle: String {
        return episode?.displayableTitle() ?? ""
    }

    var displaySubTitle: String {
        return podcast?.title ?? ""
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

    var playbackSpeed: Double {
        playbackManager.effects().playbackSpeed
    }

    func setPlaybackSpeed(speed: Double) {
        playbackManager.effects().playbackSpeed = speed
        playbackManager.applyCurrentEffect()
    }

    var volumeBoost: Bool {
        playbackManager.effects().volumeBoost
    }

    func setVolumeBoost(_ boost: Bool) {
        playbackManager.effects().volumeBoost = boost
        playbackManager.applyCurrentEffect()
    }

    private func loadEpisodeArtworkData() async -> UIImage? {
        guard let podcastUuid = episode?.parentIdentifier() else {
            return nil
        }

        let imageUrl = ImageManager.sharedManager.podcastUrl(imageSize: .page, uuid: podcastUuid)
        guard let (data, _) = try? await URLSession.shared.data(for: URLRequest.init(url: imageUrl)),
              let uiImage = UIImage(data: data)
        else {
            return nil
        }
        return uiImage
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }
}
