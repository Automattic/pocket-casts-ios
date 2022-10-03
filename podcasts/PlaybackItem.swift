import AVFoundation
import PocketCastsDataModel
import PocketCastsServer

class PlaybackItem: NSObject {
    var episode: BaseEpisode

    init(episode: BaseEpisode) {
        self.episode = episode
    }

    static func itemFromEpisode(_ episode: BaseEpisode) -> PlaybackItem? {
        PlaybackItem(episode: episode)
    }

    func createPlayerItem() -> AVPlayerItem? {
        guard let url = EpisodeManager.urlForEpisode(episode) else { return nil }

        let customHeaders = [ServerConstants.HttpHeaders.userAgent: ServerConstants.Values.appUserAgent]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": customHeaders])

        return AVPlayerItem(asset: asset)
    }
}
