import PocketCastsDataModel
import DifferenceKit

/// Returns a list of episodes
class EpisodesDataManager {
    enum Section {
        case podcast(Podcast, uuidsToFilter: [String]?)
        case filter(EpisodeFilter)
    }

    func get(_ section: Section) -> [ArraySection<String, ListItem>] {
        switch section {
        case .podcast(let podcast, uuidsToFilter: let uuidsToFilter):
            return episodes(for: podcast, uuidsToFilter: uuidsToFilter)
        case .filter:
            fatalError("ArraySection can't be returned for filters")
        }
    }

    func get(_ section: Section) -> [ListEpisode] {
        switch section {
        case .podcast(_, uuidsToFilter: _):
            fatalError("An array of ListEpisode can't be returned for a podcast")
        case .filter(let filter):
            return episodes(for: filter)
        }
    }

    // MARK: - Podcast episodes list

    func episodes(for podcast: Podcast, uuidsToFilter: [String]? = nil) -> [ArraySection<String, ListItem>] {
        // the podcast page has a header, for simplicity in table animations, we add it here
        let searchHeader = ListHeader(headerTitle: L10n.search, isSectionHeader: true)
        var newData = [ArraySection<String, ListItem>(model: searchHeader.headerTitle, elements: [searchHeader])]

        let tintColor = AppTheme.appTintColor()
        let sortOrder = PodcastEpisodeSortOrder(rawValue: podcast.episodeSortOrder) ?? .newestToOldest
        switch podcast.podcastGrouping() {
        case .none:
            let episodes = EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil)
            newData.append(ArraySection(model: "episodes", elements: episodes))
        case .season:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, name2 -> Bool in
                sortOrder == .newestToOldest ? name1.digits > name2.digits : name2.digits > name1.digits
            }, episodeShortKey: { episode -> String in
                episode.seasonNumber > 0 ? L10n.podcastSeasonFormat(episode.seasonNumber.localized()) : L10n.podcastNoSeason
            })
            newData.append(contentsOf: groupedEpisodes)
        case .unplayed:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusUnplayed
            }, episodeShortKey: { episode -> String in
                episode.played() ? L10n.statusPlayed : L10n.statusUnplayed
            })
            newData.append(contentsOf: groupedEpisodes)
        case .downloaded:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusDownloaded
            }, episodeShortKey: { (episode: Episode) -> String in
                episode.downloaded(pathFinder: DownloadManager.shared) || episode.queued() || episode.downloading() ? L10n.statusDownloaded : L10n.statusNotDownloaded
            })
            newData.append(contentsOf: groupedEpisodes)
        case .starred:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
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
        let sortOrder = PodcastEpisodeSortOrder(rawValue: podcast.episodeSortOrder) ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .newestToOldest:
            sortStr = "ORDER BY publishedDate DESC, addedDate DESC"
        case .oldestToNewest:
            sortStr = "ORDER BY publishedDate ASC, addedDate ASC"
        case .shortestToLongest:
            sortStr = "ORDER BY duration ASC, addedDate"
        case .longestToShortest:
            sortStr = "ORDER BY duration DESC, addedDate"
        }
        if let uuids = uuidsToFilter {
            let inClause = "(\(uuids.map { "'\($0)'" }.joined(separator: ",")))"
            return "podcast_id = \(podcast.id) AND uuid IN \(inClause) \(sortStr)"
        }
        if !podcast.showArchived {
            return "podcast_id = \(podcast.id) AND archived = 0 \(sortStr)"
        }

        return "podcast_id = \(podcast.id) \(sortStr)"
    }

    // MARK: - Filters

    func episodes(for filter: EpisodeFilter) -> [ListEpisode] {
        let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.maxFilterItems)
        let tintColor = filter.playlistColor()
        return EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: query, arguments: nil)
    }
}
