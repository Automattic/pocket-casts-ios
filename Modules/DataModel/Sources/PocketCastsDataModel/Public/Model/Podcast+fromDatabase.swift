import Foundation
import PocketCastsUtils
import FMDB
import GRDB

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

        return podcast
    }

    static func from(row: RowCursor.Element) -> Podcast {
        let podcast = Podcast()
        podcast.id = row["id"]
        podcast.addedDate = row["addedDate"]
        podcast.autoDownloadSetting = row["autoDownloadSetting"]
        podcast.autoAddToUpNext = row["autoAddToUpNext"]
        podcast.autoArchiveEpisodeLimit = row["episodeKeepSetting"]
        podcast.backgroundColor = row["backgroundColor"]
        podcast.detailColor = row["detailColor"]
        podcast.primaryColor = row["primaryColor"]
        podcast.secondaryColor = row["secondaryColor"]
        podcast.lastColorDownloadDate = row["lastColorDownloadDate"]
        podcast.imageURL = row["imageURL"]
        podcast.latestEpisodeUuid = row["latestEpisodeUuid"]
        podcast.latestEpisodeDate = row["latestEpisodeDate"]
        podcast.mediaType = row["mediaType"]
        podcast.lastThumbnailDownloadDate = row["lastThumbnailDownloadDate"]
        podcast.thumbnailStatus = row["thumbnailStatus"]
        podcast.podcastUrl = row["podcastUrl"]
        podcast.author = row["author"]
        podcast.playbackSpeed = row["playbackSpeed"]
        podcast.boostVolume = row["boostVolume"]
        podcast.trimSilenceAmount = row["trimSilenceAmount"]
        podcast.podcastCategory = row["podcastCategory"]
        podcast.podcastDescription = row["podcastDescription"]
        podcast.sortOrder = row["sortOrder"]
        podcast.startFrom = row["startFrom"]
        podcast.skipLast = row["skipLast"]
        podcast.subscribed = row["subscribed"]
        podcast.title = row["title"]
        podcast.uuid = row["uuid"]
        podcast.syncStatus = row["syncStatus"]
        podcast.colorVersion = row["colorVersion"]
        podcast.pushEnabled = row["pushEnabled"]
        podcast.episodeSortOrder = row["episodeSortOrder"]
        podcast.showType = row["showType"]
        podcast.estimatedNextEpisode = row["estimatedNextEpisode"]
        podcast.episodeFrequency = row["episodeFrequency"]
        podcast.lastUpdatedAt = row["lastUpdatedAt"]
        podcast.excludeFromAutoArchive = row["excludeFromAutoArchive"]
        podcast.overrideGlobalEffects = row["overrideGlobalEffects"]
        podcast.overrideGlobalArchive = row["overrideGlobalArchive"]
        podcast.autoArchivePlayedAfter = row["autoArchivePlayedAfter"]
        podcast.autoArchiveInactiveAfter = row["autoArchiveInactiveAfter"]
        podcast.episodeGrouping = row["episodeGrouping"]
        podcast.isPaid = row["isPaid"]
        podcast.licensing = row["licensing"]
        podcast.fullSyncLastSyncAt = row["fullSyncLastSyncAt"]
        podcast.showArchived = row["showArchived"]
        podcast.refreshAvailable = row["refreshAvailable"]
        podcast.folderUuid = row["folderUuid"]

        return podcast
    }
}

extension DBUtils {
    static func convertData<T: JSONCodable>(value: Data) throws -> T? {
        return try JSONDecoder().decode(T.self, from: value)
    }
}

extension ModifiedDate: JSONCodable {}
