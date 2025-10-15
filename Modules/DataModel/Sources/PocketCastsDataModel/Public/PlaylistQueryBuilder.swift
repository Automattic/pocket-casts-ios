import Foundation
import RegexBuilder

public class PlaylistQueryBuilder {
    public enum SelectClause {
        case episode
        case episodeCount
        case podcast
    }

    private enum QueryResult {
        case value(String, Bool)

        var value: String {
            switch self {
            case .value(let value, _):
                return value
            }
        }

        var boolValue: Bool {
            switch self {
            case .value(_, let boolValue):
                return boolValue
            }
        }
    }

    public class func query(
        clause: SelectClause,
        for playlist: EpisodeFilter,
        episodeUuidToAdd: String? = nil,
        searchTerm: String? = nil,
        limit: Int = 0
    ) -> String {

        var queryString: String = ""

        if playlist.manual {
            let manualCTE =
                """
                WITH playlist AS (
                  SELECT episodeUuid, MIN(episodePosition) AS pos
                  FROM \(DataManager.playlistEpisodeTableName)
                  WHERE playlist_uuid = '\(playlist.uuid)'
                  GROUP BY episodeUuid
                ),
                deduped_episode AS (
                  SELECT episode.*,
                         ROW_NUMBER() OVER (
                           PARTITION BY episode.uuid
                           ORDER BY
                             CASE WHEN episode.episodeStatus = 1 THEN 0 ELSE 1 END,
                             episode.id ASC
                         ) AS rn
                  FROM \(DataManager.episodeTableName) episode
                )
                """

            let manualJoin =
                """
                FROM playlist p
                JOIN deduped_episode episode
                  ON episode.uuid = p.episodeUuid
                  AND episode.rn = 1
                LEFT JOIN \(DataManager.podcastTableName) podcast
                  ON episode.podcast_id = podcast.id
                WHERE episode.archived = 0
                """

            switch clause {
            case .episode:
                queryString =
                    """
                    \(manualCTE)
                    SELECT episode.*
                    \(manualJoin)
                    """
            case .episodeCount:
                queryString =
                    """
                    \(manualCTE)
                    SELECT COUNT(*)
                    \(manualJoin)
                    """
            case .podcast:
                let select = manualSelect(clause: clause, for: playlist)
                queryString = "\(select) WHERE episode.archived = 0"
            }
        } else {
            let select = select(clause: clause)

            var queryValues = [QueryResult]()
            let addedUuid = add(episodeUuidToAdd: episodeUuidToAdd)
            queryValues.append(addedUuid)
            queryValues.append(add(smartRulesFor: playlist))
            let stringifiedValues = queryValues.map({$0.value}).joined(separator: " ")

            queryString = "\(select) WHERE episode.archived = 0 \(stringifiedValues)"
            queryString += ")"
            if addedUuid.boolValue {
                queryString += ")"
            }
        }

        func emptyGroup(for keyword: String) -> Regex<Substring> {
            Regex {
                keyword
                ZeroOrMore(.whitespace)
                "("
                ZeroOrMore(.whitespace)
                ")"
            }
        }

        queryString.replace(emptyGroup(for: "AND"), with: "")
        queryString.replace(emptyGroup(for: "OR"), with: "OR (1)")
        if let searchTerm {
            queryString += " AND (UPPER(episode.title) LIKE '%\(searchTerm.uppercased())%' ESCAPE '\\'"
            queryString += " OR UPPER(podcast.title) LIKE '%\(searchTerm.uppercased())%'  ESCAPE '\\')"
        }
        if let sort = add(sortFor: playlist.sortType), clause != .episodeCount {
            queryString += " \(sort) "
        }
        if limit > 0 { queryString += " LIMIT \(limit)" }
        return queryString
    }

    public class func podcastExistsInPlaylistEpisodesQuery(includeDeleted: Bool = false) -> String {
        let deletedClause = includeDeleted ? "" : " AND wasDeleted = 0"
        return "SELECT 1 FROM \(DataManager.playlistEpisodeTableName) WHERE podcastUuid = ?\(deletedClause) LIMIT 1"
    }

    private static func select(clause: SelectClause) -> String {
        switch clause {
        case .episode:
            return "SELECT episode.* FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        case .episodeCount:
            return "SELECT COUNT(*) FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        case .podcast:
            return "SELECT DISTINCT podcast.* FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        }
    }

    private static func manualSelect(clause: SelectClause, for playlist: EpisodeFilter) -> String {
        switch clause {
        case .episode:
            return "SELECT episode.* FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        case .episodeCount:
            return "SELECT COUNT(*) FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        case .podcast:
            return "SELECT DISTINCT podcast.* FROM \(DataManager.episodeTableName) episode LEFT JOIN \(DataManager.podcastTableName) podcast ON episode.podcast_id = podcast.id"
        }
    }

    private static func add(episodeUuidToAdd uuids: String?) -> QueryResult {
        if let uuids {
            return .value("AND ((episode.uuid = '\(uuids)') OR (", true)
        }
        return .value("AND (", false)
    }

    private static func add(sortFor sortType: Int32) -> String? {
        guard let sort = PlaylistSort(rawValue: sortType) else {
            return nil
        }
        switch sort {
        case .oldestToNewest:
            return "ORDER BY episode.publishedDate ASC, episode.addedDate ASC"
        case .newestToOldest:
            return "ORDER BY episode.publishedDate DESC, episode.addedDate DESC"
        case .shortestToLongest:
            return "ORDER BY episode.duration ASC, episode.addedDate ASC"
        case .longestToShortest:
            return "ORDER BY episode.duration DESC, episode.addedDate DESC"
        case .dragAndDrop:
            return "ORDER BY p.pos ASC" // Only for manual playlist
        }
    }

    private static func add(smartRulesFor playlist: EpisodeFilter) -> QueryResult {
        var queryString = ""
        var haveStartedWhere = false

        buildPlayingStatusQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildAudioVideoQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildDownloadStatusQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildFilterDurationQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildStarredQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildParticularPodcastsQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        filterUnsubscribedPodcastsQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        buildFilterHoursQuery(
            playlist: playlist,
            queryString: &queryString,
            haveStartedWhere: &haveStartedWhere
        )

        return .value(queryString, haveStartedWhere)
    }

    private static func buildPlayingStatusQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if !(playlist.filterUnplayed && playlist.filterPartiallyPlayed && playlist.filterFinished), playlist.filterUnplayed || playlist.filterPartiallyPlayed || playlist.filterFinished {
            queryString += "("
            if playlist.filterUnplayed {
                queryString += "episode.playingStatus = \(PlayingStatus.notPlayed.rawValue) "
            }
            if playlist.filterPartiallyPlayed {
                if playlist.filterUnplayed { queryString += "OR " }

                queryString += "episode.playingStatus = \(PlayingStatus.inProgress.rawValue) "
            }
            if playlist.filterFinished {
                if playlist.filterUnplayed || playlist.filterPartiallyPlayed { queryString += "OR " }

                queryString += "episode.playingStatus = \(PlayingStatus.completed.rawValue)"
            }

            queryString += ") "
            haveStartedWhere = true
        }
    }

    private static func buildDownloadStatusQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if !(playlist.filterDownloaded && playlist.filterDownloading && playlist.filterNotDownloaded), playlist.filterDownloaded || playlist.filterDownloading || playlist.filterNotDownloaded {
            if haveStartedWhere { queryString += "AND " }
            queryString += "("
            if playlist.filterDownloaded {
                queryString += "episode.episodeStatus = \(DownloadStatus.downloaded.rawValue) "
            }
            if playlist.filterDownloading {
                if playlist.filterDownloaded { queryString += "OR " }

                queryString += "episode.episodeStatus = \(DownloadStatus.queued.rawValue) OR episode.episodeStatus = \(DownloadStatus.downloading.rawValue) "
            }
            if playlist.filterNotDownloaded {
                if playlist.filterDownloaded || playlist.filterDownloading { queryString += "OR " }
                queryString += "episode.episodeStatus = \(DownloadStatus.notDownloaded.rawValue) OR episode.episodeStatus = \(DownloadStatus.downloadFailed.rawValue) OR episode.episodeStatus = \(DownloadStatus.waitingForWifi.rawValue) "
            }
            queryString += ") "
            haveStartedWhere = true
        }
    }

    private static func buildAudioVideoQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if playlist.filterAudioVideoType == AudioVideoFilter.videoOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }

            queryString += "episode.fileType LIKE 'video%' "
            haveStartedWhere = true
        }

        if playlist.filterAudioVideoType == AudioVideoFilter.audioOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }

            queryString += "episode.fileType LIKE 'audio%' "
            haveStartedWhere = true
        }
    }

    private static func buildFilterDurationQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if playlist.filterDuration {
            if haveStartedWhere { queryString += "AND " }

            let longerThanTime = (playlist.longerThan * 60)
            // we add 59s here to account for how iOS doesn't show "10m" until you get to 10*60 seconds, that way our visual representation lines up with the filter times
            let shorterThanTime = (playlist.shorterThan * 60) + 59

            queryString += "(episode.duration >= \(longerThanTime) AND episode.duration <= \(shorterThanTime)) "

            haveStartedWhere = true
        }
    }

    private static func buildStarredQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if playlist.filterStarred {
            if haveStartedWhere { queryString += "AND " }

            queryString += "episode.keepEpisode = 1 "
            haveStartedWhere = true
        }
    }

    private static func buildParticularPodcastsQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if !playlist.filterAllPodcasts, playlist.podcastUuids.count > 0, playlist.podcastUuids != "null" {
            if haveStartedWhere { queryString += "AND " }

            let podcastUuidArr = playlist.podcastUuids.components(separatedBy: ",")
            queryString += " episode.podcastUuid in ("
            for (index, uuid) in podcastUuidArr.enumerated() {
                queryString += "\(index > 0 ? "," : "")'\(uuid)'"
            }
            queryString += ") "
            haveStartedWhere = true
        }
    }

    private static func filterUnsubscribedPodcastsQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        let unsubscribedUuids = DataManager.sharedManager.allUnsubscribedPodcastUuids()
        if unsubscribedUuids.count > 0 {
            if haveStartedWhere { queryString += "AND " }

            queryString += " episode.podcastUuid NOT IN ("
            for (index, uuid) in unsubscribedUuids.enumerated() {
                queryString += "\(index > 0 ? "," : "")'\(uuid)'"
            }
            queryString += ") "
            haveStartedWhere = true
        }
    }

    private static func buildFilterHoursQuery(
        playlist: EpisodeFilter,
        queryString: inout String,
        haveStartedWhere: inout Bool
    ) {
        if playlist.filterHours > 0 {
            if haveStartedWhere { queryString += "AND " }

            queryString += "episode.publishedDate > \(filterTimeFor(hours: playlist.filterHours)) "
             haveStartedWhere = true
        }
    }

    // MARK: - Legacy

    public class func queryFor(filter: EpisodeFilter, episodeUuidToAdd: String?, limit: Int) -> String {
        var queryString = "archived = 0 "
        var addedUuid = false

        if let episodeUuidToAdd = episodeUuidToAdd {
            queryString += "AND ((uuid = '\(episodeUuidToAdd)') OR ("
            addedUuid = true
        } else {
            queryString += "AND ("
        }

        var haveStartedWhere = false
        // Playing Status
        if !(filter.filterUnplayed && filter.filterPartiallyPlayed && filter.filterFinished), filter.filterUnplayed || filter.filterPartiallyPlayed || filter.filterFinished {
            queryString += "("
            if filter.filterUnplayed {
                queryString += "playingStatus = \(PlayingStatus.notPlayed.rawValue) "
            }
            if filter.filterPartiallyPlayed {
                if filter.filterUnplayed { queryString += "OR " }

                queryString += "playingStatus = \(PlayingStatus.inProgress.rawValue) "
            }
            if filter.filterFinished {
                if filter.filterUnplayed || filter.filterPartiallyPlayed { queryString += "OR " }

                queryString += "playingStatus = \(PlayingStatus.completed.rawValue)"
            }

            queryString += ") "
            haveStartedWhere = true
        }

        // Audio & Video
        if filter.filterAudioVideoType == AudioVideoFilter.videoOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }

            queryString += "fileType LIKE 'video%' "
            haveStartedWhere = true
        }
        if filter.filterAudioVideoType == AudioVideoFilter.audioOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }

            queryString += "fileType LIKE 'audio%' "
            haveStartedWhere = true
        }

        // Download Status
        if !(filter.filterDownloaded && filter.filterDownloading && filter.filterNotDownloaded), filter.filterDownloaded || filter.filterDownloading || filter.filterNotDownloaded {
            if haveStartedWhere { queryString += "AND " }
            queryString += "("
            if filter.filterDownloaded {
                queryString += "episodeStatus = \(DownloadStatus.downloaded.rawValue) "
            }
            if filter.filterDownloading {
                if filter.filterDownloaded { queryString += "OR " }

                queryString += "episodeStatus = \(DownloadStatus.queued.rawValue) OR episodeStatus = \(DownloadStatus.downloading.rawValue) "
            }
            if filter.filterNotDownloaded {
                if filter.filterDownloaded || filter.filterDownloading { queryString += "OR " }
                queryString += "episodeStatus = \(DownloadStatus.notDownloaded.rawValue) OR episodeStatus = \(DownloadStatus.downloadFailed.rawValue) OR episodeStatus = \(DownloadStatus.waitingForWifi.rawValue) "
            }
            queryString += ") "
            haveStartedWhere = true
        }

        // Duration filtering
        if filter.filterDuration {
            if haveStartedWhere { queryString += "AND " }

            let longerThanTime = (filter.longerThan * 60)
            // we add 59s here to account for how iOS doesn't show "10m" until you get to 10*60 seconds, that way our visual representation lines up with the filter times
            let shorterThanTime = (filter.shorterThan * 60) + 59

            queryString += "(duration >= \(longerThanTime) AND duration <= \(shorterThanTime)) "

            haveStartedWhere = true
        }

        // Starred only
        if filter.filterStarred {
            if haveStartedWhere { queryString += "AND " }

            queryString += "keepEpisode = 1 "
            haveStartedWhere = true
        }

        // particular podcasts only
        if !filter.filterAllPodcasts, filter.podcastUuids.count > 0, filter.podcastUuids != "null" {
            if haveStartedWhere { queryString += "AND " }

            let podcastUuidArr = filter.podcastUuids.components(separatedBy: ",")
            queryString += " podcastUuid in ("
            for (index, uuid) in podcastUuidArr.enumerated() {
                queryString += "\(index > 0 ? "," : "")'\(uuid)'"
            }
            queryString += ") "
            haveStartedWhere = true
        }

        // filter out unsubscribed podcasts
        let unsubscribedUuids = DataManager.sharedManager.allUnsubscribedPodcastUuids()
        if unsubscribedUuids.count > 0 {
            if haveStartedWhere { queryString += "AND " }

            queryString += " podcastUuid NOT IN ("
            for (index, uuid) in unsubscribedUuids.enumerated() {
                queryString += "\(index > 0 ? "," : "")'\(uuid)'"
            }
            queryString += ") "
            haveStartedWhere = true
        }

        // time based filtering
        if filter.filterHours > 0 {
            if haveStartedWhere { queryString += "AND " }

            queryString += "publishedDate > \(filterTimeFor(hours: filter.filterHours)) "
            // haveStartedWhere = true
        }

        queryString += ")"
        queryString = queryString.replacingOccurrences(of: "AND ()", with: "")
        queryString = queryString.replacingOccurrences(of: "OR ()", with: "OR (1)")

        if addedUuid { queryString += ")" }

        if filter.sortType == PlaylistSort.oldestToNewest.rawValue {
            queryString += " ORDER BY publishedDate ASC, addedDate ASC"
        } else if filter.sortType == PlaylistSort.newestToOldest.rawValue {
            queryString += " ORDER BY publishedDate DESC, addedDate DESC"
        } else if filter.sortType == PlaylistSort.shortestToLongest.rawValue {
            queryString += " ORDER BY duration ASC, addedDate ASC"
        } else if filter.sortType == PlaylistSort.longestToShortest.rawValue {
            queryString += " ORDER BY duration DESC, addedDate DESC"
        }

        if limit > 0 {
            queryString += " LIMIT \(limit)"
        }

        return queryString
    }

    private class func filterTimeFor(hours: Int32) -> TimeInterval {
        let changedTime = Date(timeIntervalSinceNow: TimeInterval(hours * -3600))

        return changedTime.timeIntervalSince1970
    }
}
