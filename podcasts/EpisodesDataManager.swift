import PocketCastsDataModel
import PocketCastsServer
import DifferenceKit

class EpisodesDataManager {
    // MARK: - Playlist episodes

    /// Return the list of episodes for a given playlist
    func episodes(for playlist: AutoplayHelper.Playlist) -> [BaseEpisode] {
        switch playlist {
        case .podcast(uuid: let uuid):
            if let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
                return episodes(for: podcast).flatMap { $0.elements.compactMap { ($0 as? ListEpisode)?.episode } }
            }
        case .filter(uuid: let uuid):
            if let filter = DataManager.sharedManager.findPlaylist(uuid: uuid) {
                return episodes(for: filter).map { $0.episode }
            }
        case .downloads:
            return downloadedEpisodes().flatMap { $0.elements.map { $0.episode } }
        case .files:
            return uploadedEpisodes()
        case .starred:
            return starredEpisodes().map { $0.episode }
        }

        return  []
    }

    // MARK: - Podcast episodes list

    /// Returns a podcasts episodes that are grouped by `PodcastGrouping`
    /// Use `uuidsToFilter` to filter the episode UUIDs to only those in the array
    func episodes(for podcast: Podcast, uuidsToFilter: [String]? = nil) -> [ArraySection<String, ListItem>] {
        // the podcast page has a header, for simplicity in table animations, we add it here
        let searchHeader = ListHeader(headerTitle: L10n.search, isSectionHeader: true, sectionNumber: -1)
        var newData = [ArraySection<String, ListItem>(model: searchHeader.headerTitle, elements: [searchHeader])]

        let episodeSortOrder = podcast.podcastSortOrder

        let sortOrder = episodeSortOrder ?? .newestToOldest
        switch podcast.podcastGrouping() {
        case .none:
            let episodes = EpisodeTableHelper.loadEpisodes(query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil)
            newData.append(ArraySection(model: "episodes", elements: episodes))
        case .season:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, name2 -> Bool in
                if sortOrder == .serial {
                    if name2 == L10n.podcastExtras {
                        return true
                    } else if name1 == L10n.podcastExtras {
                        return false
                    } else {
                        return name2.digits > name1.digits
                    }
                } else {
                    return sortOrder == .newestToOldest ? name1.digits > name2.digits : name2.digits > name1.digits
                }
            }, episodeShortKey: { episode -> String in
                episode.seasonNumber > 0 ? L10n.podcastSeasonFormat(episode.seasonNumber.localized()) : (sortOrder == .serial ? L10n.podcastExtras : L10n.podcastNoSeason)
            })
            newData.append(contentsOf: groupedEpisodes)
        case .unplayed:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusUnplayed
            }, episodeShortKey: { episode -> String in
                episode.played() ? L10n.statusPlayed : L10n.statusUnplayed
            })
            newData.append(contentsOf: groupedEpisodes)
        case .downloaded:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusDownloaded
            }, episodeShortKey: { (episode: Episode) -> String in
                episode.downloaded(pathFinder: DownloadManager.shared) || episode.queued() || episode.downloading() ? L10n.statusDownloaded : L10n.statusNotDownloaded
            })
            newData.append(contentsOf: groupedEpisodes)
        case .starred:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusStarred
            }, episodeShortKey: { episode -> String in
                episode.keepEpisode ? L10n.statusStarred : L10n.statusNotStarred
            })
            newData.append(contentsOf: groupedEpisodes)
        }

        return newData
    }

    func createEpisodesQuery(_ podcast: Podcast, uuidsToFilter: [String]? = nil) -> String {
        let sortStr: String

        let episodeSortOrder = podcast.podcastSortOrder

        let sortOrder = episodeSortOrder ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .titleAtoZ:
            sortStr = """
            ORDER BY (CASE
            WHEN UPPER(title) LIKE 'THE %' THEN SUBSTR(UPPER(title), 5)
            WHEN UPPER(title) LIKE 'A %' THEN SUBSTR(UPPER(title), 3)
            WHEN UPPER(title) LIKE 'AN %' THEN SUBSTR(UPPER(title), 4)
            ELSE UPPER(title)
            END) ASC, addedDate
            """
        case .titleZtoA:
            sortStr = """
            ORDER BY (CASE
            WHEN UPPER(title) LIKE 'THE %' THEN SUBSTR(UPPER(title), 5)
            WHEN UPPER(title) LIKE 'A %' THEN SUBSTR(UPPER(title), 3)
            WHEN UPPER(title) LIKE 'AN %' THEN SUBSTR(UPPER(title), 4)
            ELSE UPPER(title)
            END) DESC, addedDate
            """
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

        var whereClauses = ["podcast_id = \(podcast.id)"]
        if !podcast.shouldShowArchived {
            whereClauses.append("archived = 0")
        }
        if let uuids = uuidsToFilter, !uuids.isEmpty { // ignore uuid filtering if uuid list is empty or nil
            whereClauses.append("uuid IN (\(uuids.map { "'\($0)'" }.joined(separator: ",")))")
        }
        let whereStr = whereClauses.joined(separator: " AND ")

        return "\(whereStr) \(sortStr)"
    }

    // MARK: - Playlists

    func episodes(for filter: EpisodeFilter, limit: Int = Constants.Limits.maxFilterItems) -> [ListEpisode] {
        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: limit)
        let tintColor = filter.playlistColor()
        return EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: query, arguments: nil)
    }

    func playlistEpisodes(
        for playlist: EpisodeFilter,
        limit: Int = Constants.Limits.maxFilterItems,
        search: String? = nil
    ) -> [ListEpisode] {
        let query = PlaylistQueryBuilder.query(clause: .episode, for: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries(), searchTerm: search, limit: limit)
        return EpisodeTableHelper.loadPlaylistEpisodes(query: query)
    }

    // MARK: - Downloads

    func downloadedEpisodes() -> [ArraySection<String, ListEpisode>] {
        let query = "( ((downloadTaskId IS NOT NULL AND autoDownloadStatus <> \(AutoDownloadStatus.playerDownloadedForStreaming.rawValue) ) OR episodeStatus = \(DownloadStatus.downloaded.rawValue) OR episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)) OR (episodeStatus = \(DownloadStatus.downloadFailed.rawValue) AND lastDownloadAttemptDate > ?) ) ORDER BY lastDownloadAttemptDate DESC LIMIT 1000"
        let arguments = [Date().weeksAgo(1)] as [Any]

        let newData = EpisodeTableHelper.loadSectionedEpisodes(query: query, arguments: arguments, episodeShortKey: { episode -> String in
            episode.shortLastDownloadAttemptDate()
        })

        return newData
    }

    // MARK: - Listening History

    func listeningHistoryEpisodes() -> [ArraySection<String, ListEpisode>] {
        let query = "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000"

        return EpisodeTableHelper.loadSectionedEpisodes(query: query, arguments: nil, episodeShortKey: { episode -> String in
            episode.shortLastPlaybackInteractionDate()
        })
    }

    func searchEpisodes(for search: String, listenedTo: Bool = true) -> [ArraySection<String, ListEpisode>] {
        return EpisodeTableHelper.searchSectionedEpisodes(for: search, listenedTo: listenedTo, episodeShortKey: { episode -> String in
            episode.shortLastPlaybackInteractionDate()
        })
    }

    // MARK: - Starred

    func starredEpisodes() -> [ListEpisode] {
        let query = "keepEpisode = 1 ORDER BY starredModified DESC LIMIT 1000"
        return EpisodeTableHelper.loadEpisodes(query: query, arguments: nil)
    }

    // MARK: - Uploaded Files

    func uploadedEpisodes() -> [UserEpisode] {
        let sortBy = UploadedSort(rawValue: Settings.userEpisodeSortBy()) ?? UploadedSort.newestToOldest

        if SubscriptionHelper.hasActiveSubscription() {
            return DataManager.sharedManager.allUserEpisodes(sortedBy: sortBy)
        } else {
            return DataManager.sharedManager.allUserEpisodesDownloaded(sortedBy: sortBy)
        }
    }
}
