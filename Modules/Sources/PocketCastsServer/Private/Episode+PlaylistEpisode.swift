import PocketCastsDataModel
import Foundation

extension Episode {
    convenience init(_ playlistEpisode: Api_SyncPlaylistEpisode) {
        self.init()

        uuid = playlistEpisode.episode
        podcastUuid = playlistEpisode.podcast
        addedDate = Date(timeIntervalSince1970: TimeInterval(playlistEpisode.added.value))
        title = playlistEpisode.title.value
        downloadUrl = playlistEpisode.url.value
    }
}
