import Foundation
import FMDB

extension Episode {
    static func from(resultSet rs: FMResultSet) -> Episode {
        let episode = Episode()
        episode.initializeFrom(resultSet: rs)
        return episode
    }
    
    func initializeFrom(resultSet rs: FMResultSet) -> Void {
        self.id = rs.longLongInt(forColumn: "id")
        self.addedDate = DBUtils.convertDate(value: rs.double(forColumn: "addedDate"))
        self.lastDownloadAttemptDate = DBUtils.convertDate(value: rs.double(forColumn: "lastDownloadAttemptDate"))
        self.detailedDescription = rs.string(forColumn: "detailedDescription")
        self.downloadErrorDetails = rs.string(forColumn: "downloadErrorDetails")
        self.downloadTaskId = rs.string(forColumn: "downloadTaskId")
        self.downloadUrl = rs.string(forColumn: "downloadUrl")
        self.episodeDescription = rs.string(forColumn: "episodeDescription")
        self.episodeStatus = rs.int(forColumn: "episodeStatus")
        self.fileType = rs.string(forColumn: "fileType")
        self.keepEpisode = rs.bool(forColumn: "keepEpisode")
        self.playedUpTo = rs.double(forColumn: "playedUpTo")
        self.duration = rs.double(forColumn: "duration")
        self.playingStatus = rs.int(forColumn: "playingStatus")
        self.autoDownloadStatus = rs.int(forColumn: "autoDownloadStatus")
        self.publishedDate = DBUtils.convertDate(value: rs.double(forColumn: "publishedDate"))
        self.sizeInBytes = rs.longLongInt(forColumn: "sizeInBytes")
        self.playingStatusModified = rs.longLongInt(forColumn: "playingStatusModified")
        self.playedUpToModified = rs.longLongInt(forColumn: "playedUpToModified")
        self.durationModified = rs.longLongInt(forColumn: "durationModified")
        self.keepEpisodeModified = rs.longLongInt(forColumn: "keepEpisodeModified")
        self.title = rs.string(forColumn: "title")
        self.uuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "uuid")
        self.podcastUuid = DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "podcastUuid")
        self.playbackErrorDetails = rs.string(forColumn: "playbackErrorDetails")
        self.cachedFrameCount = rs.longLongInt(forColumn: "cachedFrameCount")
        self.lastPlaybackInteractionDate = DBUtils.convertDate(value: rs.double(forColumn: "lastPlaybackInteractionDate"))
        self.lastPlaybackInteractionSyncStatus = rs.int(forColumn: "lastPlaybackInteractionSyncStatus")
        self.podcast_id = rs.longLongInt(forColumn: "podcast_id")
        self.episodeNumber = rs.longLongInt(forColumn: "episodeNumber")
        self.seasonNumber = rs.longLongInt(forColumn: "seasonNumber")
        self.episodeType = rs.string(forColumn: "episodeType")
        self.archived = rs.bool(forColumn: "archived")
        self.archivedModified = rs.longLongInt(forColumn: "archivedModified")
        self.lastArchiveInteractionDate = DBUtils.convertDate(value: rs.double(forColumn: "lastArchiveInteractionDate"))
        self.excludeFromEpisodeLimit = rs.bool(forColumn: "excludeFromEpisodeLimit")
        self.starredModified = rs.longLongInt(forColumn: "starredModified")
        self.alreadyHydrated = true
    }
}
