import Foundation
import PocketCastsDataModel

public extension Episode {
    func populate(fromEpisode updateEpisode: RefreshEpisode) {
        title = updateEpisode.title
        uuid = updateEpisode.uuid ?? ""
        downloadUrl = updateEpisode.url
        episodeDescription = updateEpisode.episodeDescription
        detailedDescription = updateEpisode.detailedDescription
        fileType = updateEpisode.fileType
        sizeInBytes = updateEpisode.sizeInBytes ?? 0
        duration = updateEpisode.duration ?? 0
        episodeType = updateEpisode.episodeType
        seasonNumber = updateEpisode.seasonNumber ?? 0
        episodeNumber = updateEpisode.episodeNumber ?? 0
        publishedDate = JsonUtil.convert(jsonDate: updateEpisode.publishedDate)
    }
}
