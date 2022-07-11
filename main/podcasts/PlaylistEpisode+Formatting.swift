import Foundation
import PocketCastsDataModel

extension PlaylistEpisode {
    func isUserEpisode() -> Bool {
        podcastUuid == DataConstants.userEpisodeFakePodcastId
    }
}
