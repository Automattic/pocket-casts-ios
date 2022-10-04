import PocketCastsServer
import UIKit

class IncomingShareItem {
    var podcastHeader: PodcastHeader?
    var episodeHeader: EpisodeHeader?
    var fromTime: String?

    func isPodcastOnly() -> Bool {
        episodeHeader == nil
    }
}
