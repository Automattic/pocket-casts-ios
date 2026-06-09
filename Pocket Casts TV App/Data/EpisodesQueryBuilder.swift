import PocketCastsDataModel

enum EpisodesQueryBuilder {

    static func makeEpisodeQuery(podcast: Podcast, sortOrder: PodcastEpisodeSortOrder? = nil, includeArchived: Bool = false) -> (query: String, arguments: [Any]) {

        let episodeSortOrder = sortOrder ?? podcast.podcastSortOrder

        let sortStr: String
        let sortOrder = episodeSortOrder ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .titleAtoZ:
            sortStr = "ORDER BY title ASC, addedDate"
        case .titleZtoA:
            sortStr = "ORDER BY title DESC, addedDate"
        case .newestToOldest:
            sortStr = "ORDER BY publishedDate DESC, addedDate DESC"
        case .oldestToNewest:
            sortStr = "ORDER BY publishedDate ASC, addedDate ASC"
        case .shortestToLongest:
            sortStr = "ORDER BY duration ASC, addedDate"
        case .longestToShortest:
            sortStr = "ORDER BY duration DESC, addedDate"
        case .serial:
            sortStr = "ORDER BY CASE WHEN seasonNumber < 1 THEN 9999 ELSE seasonNumber END, CASE WHEN episodeNumber < 1 THEN 9999 ELSE episodeNumber END ASC, publishedDate ASC"
        }

        let archivedFilter = includeArchived ? "" : "AND archived = 0 "
        return ("podcast_id = ? \(archivedFilter)AND wasDeleted = 0 \(sortStr)", [podcast.id])
    }
}
