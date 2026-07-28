import Kingfisher
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

class WatchImageHelper {
    static let shared = WatchImageHelper()

    // Discover Cache
    var mainCache = ImageCache(name: "mainCache")

    init() {
        mainCache.diskStorage.config.sizeLimit = UInt(30.megabytes)
        mainCache.diskStorage.config.expiration = .days(45)
        // the Series 3 Apple watch is slower and has tighter resources, so set our settings there a bit more aggressively
        if DeviceUtil.identifier.lowercased().startsWith(string: "watch3") {
            mainCache.memoryStorage.config.totalCostLimit = Int(1.megabytes)
            mainCache.memoryStorage.config.expiration = .seconds(2.minutes)
        } else {
            mainCache.memoryStorage.config.totalCostLimit = Int(5.megabytes)
            mainCache.memoryStorage.config.expiration = .seconds(10.minutes)
        }
    }

    class func imageUrl(size: Int, podcastUuid: String) -> String {
        ServerHelper.image(podcastUuid: podcastUuid, size: size)
    }

    class func largeImageUrl(episode: BaseEpisode) -> URL {
        if let userEpisode = episode as? UserEpisode {
            return userEpisode.urlForImage(size: 960)
        }

        return ServerHelper.imageUrl(podcastUuid: episode.parentIdentifier(), size: 340)
    }
}
