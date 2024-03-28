import Foundation
import PocketCastsUtils
import FMDB

extension Podcast {
    static func from(resultSet rs: FMResultSet) -> Podcast {
        let podcast = Podcast()
        podcast.id = rs.longLongInt(forColumn: "id")
        podcast.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        podcast.autoDownloadSetting = rs.int(forColumn: "autoDownloadSetting")
        podcast.autoAddToUpNext = rs.int(forColumn: "autoAddToUpNext")
        podcast.autoArchiveEpisodeLimit = rs.int(forColumn: "episodeKeepSetting")
        podcast.backgroundColor = rs.string(forColumn: "backgroundColor")
        podcast.detailColor = rs.string(forColumn: "detailColor")
        podcast.primaryColor = rs.string(forColumn: "primaryColor")
        podcast.secondaryColor = rs.string(forColumn: "secondaryColor")
        podcast.lastColorDownloadDate = DBUtils.convertDate(value: rs.double(forColumn: "lastColorDownloadDate"))
        podcast.imageURL = rs.string(forColumn: "imageURL")
        podcast.latestEpisodeUuid = rs.string(forColumn: "latestEpisodeUuid")
        podcast.latestEpisodeDate = DBUtils.convertDate(value: rs.double(forColumn: "latestEpisodeDate"))
        podcast.mediaType = rs.string(forColumn: "mediaType")
        podcast.lastThumbnailDownloadDate = DBUtils.convertDate(value: rs.double(forColumn: "lastThumbnailDownloadDate"))
        podcast.thumbnailStatus = rs.int(forColumn: "thumbnailStatus")
        podcast.podcastUrl = rs.string(forColumn: "podcastUrl")
        podcast.author = rs.string(forColumn: "author")
        podcast.playbackSpeed = rs.double(forColumn: "playbackSpeed")
        podcast.boostVolume = rs.bool(forColumn: "boostVolume")
        podcast.trimSilenceAmount = rs.int(forColumn: "trimSilenceAmount")
        podcast.podcastCategory = rs.string(forColumn: "podcastCategory")
        podcast.podcastDescription = rs.string(forColumn: "podcastDescription")
        podcast.sortOrder = rs.int(forColumn: "sortOrder")
        podcast.startFrom = rs.int(forColumn: "startFrom")
        podcast.skipLast = rs.int(forColumn: "skipLast")
        podcast.subscribed = rs.int(forColumn: "subscribed")
        podcast.title = rs.string(forColumn: "title")
        podcast.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        podcast.syncStatus = rs.int(forColumn: "syncStatus")
        podcast.colorVersion = rs.int(forColumn: "colorVersion")
        podcast.pushEnabled = rs.bool(forColumn: "pushEnabled")
        podcast.episodeSortOrder = rs.int(forColumn: "episodeSortOrder")
        podcast.showType = rs.string(forColumn: "showType")
        podcast.estimatedNextEpisode = DBUtils.convertDate(value: rs.double(forColumn: "estimatedNextEpisode"))
        podcast.episodeFrequency = rs.string(forColumn: "episodeFrequency")
        podcast.lastUpdatedAt = rs.string(forColumn: "lastUpdatedAt")
        podcast.excludeFromAutoArchive = rs.bool(forColumn: "excludeFromAutoArchive")
        podcast.overrideGlobalEffects = rs.bool(forColumn: "overrideGlobalEffects")
        podcast.overrideGlobalArchive = rs.bool(forColumn: "overrideGlobalArchive")
        podcast.autoArchivePlayedAfter = rs.double(forColumn: "autoArchivePlayedAfter")
        podcast.autoArchiveInactiveAfter = rs.double(forColumn: "autoArchiveInactiveAfter")
        podcast.episodeGrouping = rs.int(forColumn: "episodeGrouping")
        podcast.isPaid = rs.bool(forColumn: "isPaid")
        podcast.licensing = rs.int(forColumn: "licensing")
        podcast.fullSyncLastSyncAt = rs.string(forColumn: "fullSyncLastSyncAt")
        podcast.showArchived = rs.bool(forColumn: "showArchived")
        podcast.refreshAvailable = rs.bool(forColumn: "refreshAvailable")
        podcast.folderUuid = rs.string(forColumn: "folderUuid")

        if let settingsString = rs.string(forColumn: "settings"), let data = settingsString.data(using: .utf8) {
            do {
                podcast.settings = try DBUtils.convertData(value: data) ?? podcast.settings
            } catch let error {
                FileLog.shared.addMessage("Podcast fromResultSet: Failed to decode: \(error)")
            }
        } else {
            FileLog.shared.addMessage("Podcast fromResultSet: Nil settings column")
        }

        return podcast
    }
}

extension DBUtils {
    static func convertData<T: JSONCodable>(value: Data) throws -> T? {
        return try JSONDecoder().decode(T.self, from: value)
    }
}

extension ModifiedDate: JSONCodable {}
