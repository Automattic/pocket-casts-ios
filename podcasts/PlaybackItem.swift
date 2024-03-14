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
        var options: [String: Any] = [:]
        if #available(iOS 16, *), #available(watchOS 9.0, *) {
            // there is now an official, working way to set the user-agent for every request
            // https://developer.apple.com/documentation/avfoundation/avurlassethttpuseragentkey
            options[AVURLAssetHTTPUserAgentKey] = ServerConstants.Values.appUserAgent
        } else {
            let customHeaders = [ServerConstants.HttpHeaders.userAgent: ServerConstants.Values.appUserAgent]
            options["AVURLAssetHTTPHeaderFieldsKey"] = customHeaders
        }
        let asset = AVURLAsset(url: url, options: options)

        return AVPlayerItem(asset: asset)
    }
}
