import Foundation

extension Podcast {
    public static func from(podcastJson: [String: Any], podcastInfo: [String: Any], uuid: String, subscribe: Bool, autoDownloads: Int, lastModified: String?, isoFormatter: ISO8601DateFormatter) -> Podcast {
        let podcast = Podcast()
        podcast.uuid = uuid
        podcast.subscribed = subscribe ? 1 : 0
        // if we're adding a new podcast but not subscribing don't mark it as needing to be synced
        if !subscribe {
            podcast.syncStatus = SyncStatus.synced.rawValue
        }
        podcast.addedDate = Date()
        podcast.autoDownloadSetting = (autoDownloads > 0 ? AutoDownloadSetting.latest : AutoDownloadSetting.off).rawValue
        podcast.lastUpdatedAt = lastModified
        if let title = podcastJson["title"] as? String {
            podcast.title = title
        }
        if let author = podcastJson["author"] as? String {
            podcast.author = author
        }
        if let url = podcastJson["url"] as? String {
            podcast.podcastUrl = url
        }
        if let description = podcastJson["description"] as? String {
            podcast.podcastDescription = description
        }

        if let description = podcastJson["description_html"] as? String {
            podcast.podcastHTMLDescription = description
        }

        if let category = podcastJson["category"] as? String {
            podcast.podcastCategory = category
        }
        if let showType = podcastJson["show_type"] as? String {
            podcast.showType = showType
            if podcast.showType == "serial" {
                podcast.episodeGrouping = PodcastGrouping.season.rawValue
                podcast.episodeSortOrder = PodcastEpisodeSortOrder.Old.serial.rawValue
            }
        }
        if let estimatedNextEpisode = podcastInfo["estimated_next_episode_at"] as? String {
            podcast.estimatedNextEpisode = isoFormatter.date(from: estimatedNextEpisode)
        }
        if let frequency = podcastInfo["episode_frequency"] as? String {
            podcast.episodeFrequency = frequency
        }
        if let paid = podcastJson["paid"] as? Int {
            podcast.isPaid = paid > 0
        }
        if let licensing = podcastJson["licensing"] as? Int {
            podcast.licensing = Int32(licensing)
        }
        if let refreshAvailable = podcastInfo["refresh_allowed"] as? Bool {
            podcast.refreshAvailable = refreshAvailable
        }
        if let isPrivate = podcastJson["is_private"] as? Bool {
            podcast.isPrivate = isPrivate
        }
        if let fundingsJson = podcastJson["fundings"] as? [[String: Any]], let url = fundingsJson.first?["url"] as? String {
            podcast.fundingURL = url
        }

        return podcast
    }
}
