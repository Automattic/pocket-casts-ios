import Foundation
import PocketCastsDataModel

extension Podcast {
    var artworkURL: URL? {
        URL(string: WatchImageHelper.imageUrl(size: 340, podcastUuid: uuid))
    }

    var smallArtworkURL: URL? {
        URL(string: WatchImageHelper.imageUrl(size: 130, podcastUuid: uuid))
    }
}
