import Foundation

public class PlaylistHelper {
    public class func queryFor(filter: EpisodeFilter, episodeUuidToAdd: String?, limit: Int) -> String {
        var queryString = "\(field("archived")) = 0 "
        var addedUuid = false
        
        if let episodeUuidToAdd = episodeUuidToAdd {
            queryString += "AND ((\(field("uuid")) = '\(episodeUuidToAdd)') OR ("
            addedUuid = true
        }
        else {
            queryString += "AND ("
        }
        
        var haveStartedWhere = false
        // Playing Status
        if !(filter.filterUnplayed && filter.filterPartiallyPlayed && filter.filterFinished), filter.filterUnplayed || filter.filterPartiallyPlayed || filter.filterFinished {
            queryString += "("
            if filter.filterUnplayed {
                queryString += "\(field("playingStatus")) = \(PlayingStatus.notPlayed.rawValue) "
            }
            if filter.filterPartiallyPlayed {
                if filter.filterUnplayed { queryString += "OR " }
                
                queryString += "\(field("playingStatus")) = \(PlayingStatus.inProgress.rawValue) "
            }
            if filter.filterFinished {
                if filter.filterUnplayed || filter.filterPartiallyPlayed { queryString += "OR " }
                
                queryString += "\(field("playingStatus")) = \(PlayingStatus.completed.rawValue)"
            }
            
            queryString += ") "
            haveStartedWhere = true
        }
        
        // Audio & Video
        if filter.filterAudioVideoType == AudioVideoFilter.videoOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }

            queryString += "\(field("fileType")) LIKE 'video%' "
            haveStartedWhere = true
        }
        if filter.filterAudioVideoType == AudioVideoFilter.audioOnly.rawValue {
            if haveStartedWhere { queryString += "AND " }
            
            queryString += "\(field("fileType")) LIKE 'audio%' "
            haveStartedWhere = true
        }
        
        // Download Status
        if !(filter.filterDownloaded && filter.filterDownloading && filter.filterNotDownloaded), filter.filterDownloaded || filter.filterDownloading || filter.filterNotDownloaded {
            if haveStartedWhere { queryString += "AND " }
            queryString += "("
            if filter.filterDownloaded {
                queryString += "\(field("episodeStatus")) = \(DownloadStatus.downloaded.rawValue) "
            }
            if filter.filterDownloading {
                if filter.filterDownloaded { queryString += "OR " }
                
                queryString += "\(field("episodeStatus")) = \(DownloadStatus.queued.rawValue) OR \(field("episodeStatus")) = \(DownloadStatus.downloading.rawValue) "
            }
            if filter.filterNotDownloaded {
                if filter.filterDownloaded || filter.filterDownloading { queryString += "OR " }
                queryString += "\(field("episodeStatus")) = \(DownloadStatus.notDownloaded.rawValue) OR \(field("episodeStatus")) = \(DownloadStatus.downloadFailed.rawValue) OR \(field("episodeStatus")) = \(DownloadStatus.waitingForWifi.rawValue) "
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
            
            queryString += "(\(field("duration")) >= \(longerThanTime) AND \(field("duration")) <= \(shorterThanTime)) "
            
            haveStartedWhere = true
        }
        
        // Starred only
        if filter.filterStarred {
            if haveStartedWhere { queryString += "AND " }
            
            queryString += "\(field("keepEpisode")) = 1 "
            haveStartedWhere = true
        }
        
        // particular podcasts only
        if !filter.filterAllPodcasts, filter.podcastUuids.count > 0, filter.podcastUuids != "null" {
            if haveStartedWhere { queryString += "AND " }

            let podcastUuidArr = filter.podcastUuids.components(separatedBy: ",")
            queryString += " \(field("podcastUuid")) in ("
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
            
            queryString += " \(field("podcastUuid")) NOT IN ("
            for (index, uuid) in unsubscribedUuids.enumerated() {
                queryString += "\(index > 0 ? "," : "")'\(uuid)'"
            }
            queryString += ") "
            haveStartedWhere = true
        }
        
        // time based filtering
        if filter.filterHours > 0 {
            if haveStartedWhere { queryString += "AND " }

            queryString += "\(field("publishedDate")) > \(filterTimeFor(hours: filter.filterHours)) "
            // haveStartedWhere = true
        }
        
        queryString += ")"
        queryString = queryString.replacingOccurrences(of: "AND ()", with: "")
        queryString = queryString.replacingOccurrences(of: "OR ()", with: "OR (1)")
        
        if addedUuid { queryString += ")" }

        if filter.sortType == PlaylistSort.oldestToNewest.rawValue {
            queryString += " ORDER BY \(field("publishedDate")) ASC, \(field("addedDate")) ASC"
        }
        else if filter.sortType == PlaylistSort.newestToOldest.rawValue {
            queryString += " ORDER BY \(field("publishedDate")) DESC, \(field("addedDate")) DESC"
        }
        else if filter.sortType == PlaylistSort.shortestToLongest.rawValue {
            queryString += " ORDER BY \(field("duration")) ASC, \(field("addedDate")) ASC"
        }
        else if filter.sortType == PlaylistSort.longestToShortest.rawValue {
            queryString += " ORDER BY \(field("duration")) DESC, \(field("addedDate")) DESC"
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

private extension PlaylistHelper {
    /// Returns a table field name prefixed with the episode table name
    /// archived -> SJEpisode.archived
    /// This makes sure the right field is being used if there is a JOIN in the query
    static func field(_ name: String) -> String {
        return "\(DataManager.episodeTableName).\(name)"
    }
}
