import Foundation
import GRDB
import FMDB

extension Episode {
    static func from(row: RowCursor.Element) -> Episode {
        let episode = Episode()
        episode.id = row["id"]
        episode.addedDate = row["addedDate"]
        episode.lastDownloadAttemptDate = DBUtils.convertDate(value: row["lastDownloadAttemptDate"])
        episode.detailedDescription = row["detailedDescription"]
        episode.downloadErrorDetails = row["downloadErrorDetails"]
        episode.downloadTaskId = row["downloadTaskId"]
        episode.downloadUrl = row["downloadUrl"]
        episode.episodeDescription = row["episodeDescription"]
        episode.episodeStatus = row["episodeStatus"]
        episode.fileType = row["fileType"]
        episode.contentType = row["contentType"]
        episode.keepEpisode = row["keepEpisode"]
        episode.playedUpTo = row["playedUpTo"]
        episode.duration = row["duration"]
        episode.playingStatus = row["playingStatus"]
        episode.autoDownloadStatus = row["autoDownloadStatus"]
        episode.publishedDate = row["publishedDate"]
        episode.sizeInBytes = row["sizeInBytes"]
        episode.playingStatusModified = row["playingStatusModified"]
        episode.playedUpToModified = row["playedUpToModified"]
        episode.durationModified = row["durationModified"]
        episode.keepEpisodeModified = row["keepEpisodeModified"]
        episode.title = row["title"]
        episode.uuid = row["uuid"]
        episode.podcastUuid = row["podcastUuid"]
        episode.playbackErrorDetails = row["playbackErrorDetails"]
        episode.cachedFrameCount = row["cachedFrameCount"]
        episode.lastPlaybackInteractionDate = row["lastPlaybackInteractionDate"]
        episode.lastPlaybackInteractionSyncStatus = row["lastPlaybackInteractionSyncStatus"]
        episode.podcast_id = row["podcast_id"]
        episode.episodeNumber = row["episodeNumber"]
        episode.seasonNumber = row["seasonNumber"]
        episode.episodeType = row["episodeType"]
        episode.archived = row["archived"]
        episode.archivedModified = row["archivedModified"]
        episode.lastArchiveInteractionDate = row["lastArchiveInteractionDate"]
        episode.excludeFromEpisodeLimit = row["excludeFromEpisodeLimit"]
        episode.starredModified = row["starredModified"]
        episode.deselectedChapters = row["deselectedChapters"]
        episode.deselectedChaptersModified = row["deselectedChaptersModified"]
        return episode
    }

    static func from(resultSet rs: FMResultSet) -> Episode {
        let episode = Episode()
        episode.id = rs.longLongInt(forColumn: "id")
        episode.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        episode.lastDownloadAttemptDate = DBUtils.convertDate(value: rs.double(forColumn: "lastDownloadAttemptDate"))
        episode.detailedDescription = rs.string(forColumn: "detailedDescription")
        episode.downloadErrorDetails = rs.string(forColumn: "downloadErrorDetails")
        episode.downloadTaskId = rs.string(forColumn: "downloadTaskId")
        episode.downloadUrl = rs.string(forColumn: "downloadUrl")
        episode.episodeDescription = rs.string(forColumn: "episodeDescription")
        episode.episodeStatus = rs.int(forColumn: "episodeStatus")
        episode.fileType = rs.string(forColumn: "fileType")
        episode.contentType = rs.string(forColumn: "contentType")
        episode.keepEpisode = rs.bool(forColumn: "keepEpisode")
        episode.playedUpTo = rs.double(forColumn: "playedUpTo")
        episode.duration = rs.double(forColumn: "duration")
        episode.playingStatus = rs.int(forColumn: "playingStatus")
        episode.autoDownloadStatus = rs.int(forColumn: "autoDownloadStatus")
        episode.publishedDate = DBUtils.convertDate(value: rs.double(forColumn: "publishedDate"))
        episode.sizeInBytes = rs.longLongInt(forColumn: "sizeInBytes")
        episode.playingStatusModified = rs.longLongInt(forColumn: "playingStatusModified")
        episode.playedUpToModified = rs.longLongInt(forColumn: "playedUpToModified")
        episode.durationModified = rs.longLongInt(forColumn: "durationModified")
        episode.keepEpisodeModified = rs.longLongInt(forColumn: "keepEpisodeModified")
        episode.title = rs.string(forColumn: "title")
        episode.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        episode.podcastUuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "podcastUuid")
        episode.playbackErrorDetails = rs.string(forColumn: "playbackErrorDetails")
        episode.cachedFrameCount = rs.longLongInt(forColumn: "cachedFrameCount")
        episode.lastPlaybackInteractionDate = DBUtils.convertDate(value: rs.double(forColumn: "lastPlaybackInteractionDate"))
        episode.lastPlaybackInteractionSyncStatus = rs.int(forColumn: "lastPlaybackInteractionSyncStatus")
        episode.podcast_id = rs.longLongInt(forColumn: "podcast_id")
        episode.episodeNumber = rs.longLongInt(forColumn: "episodeNumber")
        episode.seasonNumber = rs.longLongInt(forColumn: "seasonNumber")
        episode.episodeType = rs.string(forColumn: "episodeType")
        episode.archived = rs.bool(forColumn: "archived")
        episode.archivedModified = rs.longLongInt(forColumn: "archivedModified")
        episode.lastArchiveInteractionDate = DBUtils.convertDate(value: rs.double(forColumn: "lastArchiveInteractionDate"))
        episode.excludeFromEpisodeLimit = rs.bool(forColumn: "excludeFromEpisodeLimit")
        episode.starredModified = rs.longLongInt(forColumn: "starredModified")
        episode.deselectedChapters = rs.string(forColumn: "deselectedChapters")
        episode.deselectedChaptersModified = rs.longLongInt(forColumn: "deselectedChaptersModified")
        return episode
    }
}
