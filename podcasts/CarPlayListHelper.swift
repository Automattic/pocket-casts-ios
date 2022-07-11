import CarPlay
import Foundation
import PocketCastsDataModel

struct CarPlayListHelper {
    let list: CPListTemplate
    let episodeLoader: () -> [BaseEpisode]
    let showsArtwork: Bool
    let closeListOnTap: Bool
}
