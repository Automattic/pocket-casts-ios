import Foundation

extension Episode {
    public static func from(episodeJson: [String: Any], podcastId: Int64, podcastUuid: String, isoFormatter: ISO8601DateFormatter) -> Episode {
        let episode = Episode()
        episode.addedDate = Date()
        episode.podcast_id = podcastId
        episode.podcastUuid = podcastUuid
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        if let uuid = episodeJson["uuid"] as? String {
            episode.uuid = uuid
        }
        if let title = episodeJson["title"] as? String {
            episode.title = title
        }
        if let url = episodeJson["url"] as? String {
            episode.downloadUrl = url
        }
        if let fileType = episodeJson["file_type"] as? String {
            episode.fileType = fileType
        }
        if let fileSize = episodeJson["file_size"] as? Int64 {
            episode.sizeInBytes = fileSize
        }
        if let duration = episodeJson["duration"] as? Double {
            episode.duration = duration
        }
        if let publishedStr = episodeJson["published"] as? String {
            episode.publishedDate = isoFormatter.date(from: publishedStr)
        }
        if let number = episodeJson["number"] as? Int64 {
            episode.episodeNumber = number
        }
        if let season = episodeJson["season"] as? Int64 {
            episode.seasonNumber = season
        }
        if let type = episodeJson["type"] as? String {
            episode.episodeType = type
        }
        return episode
    }
}
