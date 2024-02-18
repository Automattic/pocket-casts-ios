import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class EpisodeManager: NSObject {
    static var analyticsHelper = AnalyticsEpisodeHelper.shared

    class func markAsPlayed(episode: BaseEpisode, fireNotification: Bool, userInitiated: Bool = true) {
        // request to remove it from the download queue, just in case it's in there
        DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: fireNotification, userInitiated: true)

        // if the episode is currently playing then we should probably kill that
        // we always fire the episode removed notification here. It's a bit dodgy but the boolean applies to the episode meta data update
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true)

        DataManager.sharedManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: SyncManager.isUserLoggedIn())

        if shouldArchiveOnCompletion(episode: episode) {
            if let episode = episode as? Episode {
                archiveEpisode(episode: episode, fireNotification: false, userInitiated: false)
            } else if let episode = episode as? UserEpisode {
                if Settings.userEpisodeRemoveFileAfterPlaying() {
                    UserEpisodeManager.deleteFromDevice(userEpisode: episode)
                }
                if Settings.userEpisodeRemoveFromCloudAfterPlaying() {
                    UserEpisodeManager.deleteFromCloud(episode: episode)
                }
            }
        }

        if fireNotification {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodePlayStatusChanged, object: episode.uuid)
        }

        if userInitiated {
            analyticsHelper.markAsPlayed(episode: episode)
        }
    }

    class func bulkMarkAsPlayed(episodes: [BaseEpisode], updateSyncFlag: Bool) {
        guard episodes.count > 0 else { return }
        var episodesToArchive = [Episode]()
        var episodesToMarkAsPlayed = [Episode]()
        var userEpisodeToMarkAsPlayed = [UserEpisode]()

        var episodesMinusCurrent = episodes
        var currentEpisodeToMarkAsPlayed: BaseEpisode?

        if let currentEpisode = PlaybackManager.shared.currentEpisode(), let index = episodes.firstIndex(where: { $0.uuid == currentEpisode.uuid }) {
            episodesMinusCurrent.remove(at: index)
            currentEpisodeToMarkAsPlayed = currentEpisode
        }

        for baseEpisode in episodesMinusCurrent {
            DownloadManager.shared.removeFromQueue(episodeUuid: baseEpisode.uuid, fireNotification: false, userInitiated: true)

            if let userEpisode = baseEpisode as? UserEpisode {
                userEpisodeToMarkAsPlayed.append(userEpisode)
            } else if let episode = baseEpisode as? Episode {
                if shouldArchiveOnCompletion(episode: episode) {
                    episodesToArchive.append(episode)

                    deleteFilesForEpisode(episode)
                } else {
                    episodesToMarkAsPlayed.append(episode)
                }
            }
        }
        let uuids = episodesMinusCurrent.map(\.uuid)
        PlaybackManager.shared.bulkRemoveQueued(uuids: uuids)

        if episodesToArchive.count > 0 {
            DataManager.sharedManager.bulkArchive(episodes: episodesToArchive, markAsNotDownloaded: true, markAsPlayed: true, updateSyncFlag: updateSyncFlag)
        }

        if episodesToMarkAsPlayed.count > 0 {
            DataManager.sharedManager.bulkMarkAsPlayed(episodes: episodesToMarkAsPlayed, updateSyncFlag: updateSyncFlag)
        }

        if userEpisodeToMarkAsPlayed.count > 0 {
            DataManager.sharedManager.bulkMarkAsPlayed(episodes: userEpisodeToMarkAsPlayed, updateSyncFlag: updateSyncFlag)

            userEpisodeToMarkAsPlayed.forEach { userEpisode in
                // Do this last as it may delete the episode from the database
                if Settings.userEpisodeRemoveFileAfterPlaying() {
                    UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode, removeFromPlaybackQueue: false)
                }
                if Settings.userEpisodeRemoveFromCloudAfterPlaying() {
                    UserEpisodeManager.deleteFromCloud(episode: userEpisode, removeFromPlaybackQueue: false)
                }
            }
        }
        if let currentEpisode = currentEpisodeToMarkAsPlayed {
            markAsPlayed(episode: currentEpisode, fireNotification: true, userInitiated: false)
        }
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        analyticsHelper.bulkMarkAsPlayed(count: episodesMinusCurrent.count)
    }

    class func deleteDownloadedFiles(episode: BaseEpisode, userInitated: Bool = false) {
        deleteFilesForEpisode(episode)

        if episode.episodeStatus != DownloadStatus.notDownloaded.rawValue {
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            episode.autoDownloadStatus = AutoDownloadStatus.userDeletedFile.rawValue
            episode.cachedFrameCount = 0
            DataManager.sharedManager.save(episode: episode)
        }

        if userInitated {
            analyticsHelper.downloadDeleted(episode: episode)
        }
    }

    class func markEpisodeAsPlayedExternal(_ episode: Episode) {
        // request to remove it from the download queue, just in case it's in there
        DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: false, userInitiated: true)

        // if the episode is currently playing then we should probably kill that
        // we always fire the episode removed notification here. It's a bit dodgy but the boolean applies to the episode meta data update
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, saveCurrentEpisode: false)
        DataManager.sharedManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: false)

        if episode.shouldArchiveOnCompletion(), !episode.archived {
            archiveEpisode(episode: episode, fireNotification: false, removeFromPlayer: false)
        }
    }

    class func markAsUnplayed(episode: BaseEpisode, fireNotification: Bool, userInitiated: Bool = true) {
        let updateSyncFlag = SyncManager.isUserLoggedIn()

        DataManager.sharedManager.saveEpisode(playingStatus: .notPlayed, episode: episode, updateSyncFlag: updateSyncFlag)
        DataManager.sharedManager.saveEpisode(playedUpTo: 0, episode: episode, updateSyncFlag: updateSyncFlag)
        if let episode = episode as? Episode {
            DataManager.sharedManager.saveEpisode(archived: false, episode: episode, updateSyncFlag: updateSyncFlag)
        }

        if fireNotification {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodePlayStatusChanged, object: episode.uuid)
        }

        if userInitiated {
            analyticsHelper.markAsUnplayed(episode: episode)
        }
    }

    class func bulkMarkAsUnPlayed(_ baseEpisodes: [BaseEpisode]) {
        DataManager.sharedManager.bulkMarkAsUnPlayed(baseEpisodes: baseEpisodes, updateSyncFlag: SyncManager.isUserLoggedIn())
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        analyticsHelper.bulkMarkAsUnplayed(count: baseEpisodes.count)
    }

    class func archiveEpisode(episode: Episode, fireNotification: Bool, removeFromPlayer: Bool = true, userInitiated: Bool = true) {
        FileLog.shared.addMessage("Archive episode \(episode.displayableTitle()), fireNotification? \(fireNotification), removeFromPlayer? \(removeFromPlayer)")
        // request to remove it from the download queue, just in case it's in there
        DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: fireNotification, userInitiated: true)

        if removeFromPlayer {
            // we always fire the episode removed notification here. It's a bit dodgy but the boolean applies to the episode meta data update
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true)
        }

        DataManager.sharedManager.saveEpisode(archived: true, episode: episode, updateSyncFlag: SyncManager.isUserLoggedIn())

        if let latestEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid) {
            deleteDownloadedFiles(episode: latestEpisode, userInitated: false)
        }

        if fireNotification {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeArchiveStatusChanged, object: episode.uuid)
        }

        if userInitiated {
            analyticsHelper.archiveEpisode(episode)
        }
    }

    class func archiveEpisodeExternal(_ episode: Episode) {
        DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: false, userInitiated: false)
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, saveCurrentEpisode: false)

        DataManager.sharedManager.saveEpisode(archived: true, episode: episode, updateSyncFlag: false)
        if let latestEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid) {
            deleteDownloadedFiles(episode: latestEpisode, userInitated: false)
        }
    }

    class func bulkArchive(episodes: [Episode], removeFromPlayer: Bool = true, updateSyncFlag: Bool) {
        for episode in episodes {
            // request to remove it from the download queue, just in case it's in there
            DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: false, userInitiated: true)

            deleteFilesForEpisode(episode)
        }
        DataManager.sharedManager.bulkArchive(episodes: episodes, markAsNotDownloaded: true, markAsPlayed: false, updateSyncFlag: updateSyncFlag)

        if removeFromPlayer {
            let uuids = episodes.map(\.uuid)
            PlaybackManager.shared.bulkRemoveQueued(uuids: uuids)
        }
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        analyticsHelper.bulkArchiveEpisodes(count: episodes.count)
    }

    class func unarchiveEpisode(episode: Episode, fireNotification: Bool, userInitiated: Bool = true) {
        DataManager.sharedManager.saveEpisode(archived: false, episode: episode, updateSyncFlag: SyncManager.isUserLoggedIn())

        // if this podcast has an episode limit, flag this episode as being manually excluded from that limit
        if let parentPodcast = episode.parentPodcast() {
            if parentPodcast.autoArchivePlayedAfterTime > 0 {
                DataManager.sharedManager.saveEpisode(excludeFromEpisodeLimit: true, episode: episode)
            }
        }

        if fireNotification {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeArchiveStatusChanged, object: episode.uuid)
        }

        if userInitiated {
            analyticsHelper.unarchiveEpisode(episode)
        }
    }

    class func bulkUnarchive(episodes: [Episode]) {
        DataManager.sharedManager.bulkUnarchive(episodes: episodes, updateSyncFlag: SyncManager.isUserLoggedIn())

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        analyticsHelper.bulkUnarchiveEpisodes(count: episodes.count)
    }

    class func deleteAllEpisodesInPodcast(id: Int64) {
        let episodes = DataManager.sharedManager.allEpisodesForPodcast(id: id)
        if episodes.count < 1 { return }

        // make sure all the episodes are removed from the playback and download queues, as well as have their files deleted
        for episode in episodes {
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: false)

            DownloadManager.shared.removeFromQueue(episode: episode, fireNotification: false, userInitiated: false)
            deleteFilesForEpisode(episode)
        }

        // then bulk delete all the episodes
        DataManager.sharedManager.deleteAllEpisodesInPodcast(podcastId: id)
    }

    @objc class func setStarred(_ starred: Bool, episode: Episode, updateSyncStatus: Bool) {
        if starred == episode.keepEpisode { return } // we've already set this, no need to reset it again

        DataManager.sharedManager.saveEpisode(starred: starred, episode: episode, updateSyncFlag: updateSyncStatus)

        // special case if the starred status of the now playing episode is changed, tell the player to update it
        // we do this before sending notifications so that other parts of the app that grab the now playing episode get the one with the right star status
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            PlaybackManager.shared.nowPlayingStarredChanged()
        }

        if updateSyncStatus {
            ApiServerHandler.shared.saveStarred(episode: episode)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeStarredChanged, object: episode.uuid)

        if starred {
            analyticsHelper.star(episode: episode)
        } else {
            analyticsHelper.unstar(episode: episode)
        }
    }

    class func bulkSetStarred(_ starred: Bool, episodes: [Episode], updateSyncStatus: Bool) {
        DataManager.sharedManager.bulkSetStarred(starred: starred, episodes: episodes, updateSyncStatus: updateSyncStatus)
        if let currentEpisode = PlaybackManager.shared.currentEpisode() as? Episode, episodes.contains(currentEpisode) {
            PlaybackManager.shared.nowPlayingStarredChanged()
        }
        if updateSyncStatus {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        }
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        if starred {
            analyticsHelper.bulkStar(count: episodes.count)
        } else {
            analyticsHelper.bulkUnstar(count: episodes.count)
        }
    }

    class func deleteAllDownloadedFiles(unplayed: Bool, inProgress: Bool, played: Bool, includeStarred: Bool) {
        if unplayed {
            let episodes = allDownloadEpisodesWithStatus(.notPlayed, includeStarred: includeStarred)
            deleteFilesForEpisodes(episodes)
        }
        if inProgress {
            let episodes = allDownloadEpisodesWithStatus(.inProgress, includeStarred: includeStarred)
            deleteFilesForEpisodes(episodes)
        }
        if played {
            let episodes = allDownloadEpisodesWithStatus(.completed, includeStarred: includeStarred)
            deleteFilesForEpisodes(episodes)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)
    }

    class func downloadSizeOfAllEpisodes() -> UInt64 {
        let episodes = allDownloadedEpisodes()

        return fileSizeForEpisodes(episodes)
    }

    class func downloadSizeOfAllBufferEpisodes() -> UInt64 {
        let episodes = allBufferedEpisodes()

        return fileSizeForEpisodes(episodes)
    }

    class func downloadSizeOfUnplayedEpisodes(includeStarred: Bool) -> UInt64 {
        let episodes = allDownloadEpisodesWithStatus(.notPlayed, includeStarred: includeStarred)

        return fileSizeForEpisodes(episodes)
    }

    class func downloadSizeOfInProgressEpisodes(includeStarred: Bool) -> UInt64 {
        let episodes = allDownloadEpisodesWithStatus(.inProgress, includeStarred: includeStarred)

        return fileSizeForEpisodes(episodes)
    }

    class func downloadSizeOfPlayedEpisodes(includeStarred: Bool) -> UInt64 {
        let episodes = allDownloadEpisodesWithStatus(.completed, includeStarred: includeStarred)

        return fileSizeForEpisodes(episodes)
    }

    class func cleanupUnusedBuffers(episode: BaseEpisode) {
        guard episode.episodeStatus == DownloadStatus.downloadedForStreaming.rawValue else { return }

        deleteDownloadedFiles(episode: episode)
    }

    class func cleanupAllUnusedEpisodeBuffers() {
        let episodes = allBufferedEpisodes()
        for (index, episode) in episodes.enumerated() {
            guard let lastPlaybackDate = episode.lastPlaybackInteractionDate else {
                deleteDownloadedFiles(episode: episode)

                continue
            }

            // we don't want a huge number of these so if we're over 5, blow the oldest ones away
            if index >= 5, !PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
                deleteDownloadedFiles(episode: episode)

                continue
            }

            // delete episodes older than a week that we're not currently playing
            if fabs(lastPlaybackDate.timeIntervalSinceNow) > 1.week, !PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
                deleteDownloadedFiles(episode: episode)
            }
        }
    }

    class func urlForEpisode(_ episode: BaseEpisode, streamingOnly: Bool = false) -> URL? {
        if episode.downloaded(pathFinder: DownloadManager.shared), !streamingOnly {
            return URL(fileURLWithPath: episode.pathToDownloadedFile(pathFinder: DownloadManager.shared))
        } else if let episode = episode as? Episode, let url = episode.downloadUrl {
            return URL(string: url)
        } else if let episode = episode as? UserEpisode {
            if let token = ServerSettings.syncingV2Token, episode.uploadStatus != UploadStatus.missing.rawValue {
                return URL(string: "\(ServerConstants.Urls.api())files/url/\(episode.uuid)?token=\(token)")
            }
        }

        return nil
    }

    class func shouldArchiveOnCompletion(episode: BaseEpisode) -> Bool {
        if let episode = episode as? Episode {
            if let podcast = episode.parentPodcast(), podcast.overrideGlobalArchive {
                return podcast.autoArchivePlayedAfterTime == 0 && (Settings.archiveStarredEpisodes() || !episode.keepEpisode)
            }

            return Settings.autoArchivePlayedAfter() == 0 && (Settings.archiveStarredEpisodes() || !episode.keepEpisode)
        } else if let _ = episode as? UserEpisode {
            return Settings.userEpisodeRemoveFileAfterPlaying() || Settings.userEpisodeRemoveFromCloudAfterPlaying()
        }

        return false
    }

    private class func fileSizeForEpisodes(_ episodes: [Episode]) -> UInt64 {
        var fileSize = 0 as UInt64

        let fileManager = FileManager.default
        for episode in episodes {
            do {
                let fileDict = try fileManager.attributesOfItem(atPath: episode.pathToDownloadedFile(pathFinder: DownloadManager.shared))
                fileSize += fileDict[.size] as? UInt64 ?? 0
            } catch {}
        }

        return fileSize
    }

    private class func deleteFilesForEpisodes(_ episodes: [Episode]) {
        for episode in episodes {
            deleteDownloadedFiles(episode: episode)
        }
    }

    private class func allDownloadedEpisodes() -> [Episode] {
        let query = "episodeStatus == \(DownloadStatus.downloaded.rawValue)"

        return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
    }

    private class func allDownloadEpisodesWithStatus(_ playbackStatus: PlayingStatus, includeStarred: Bool) -> [Episode] {
        var query = "episodeStatus == \(DownloadStatus.downloaded.rawValue) AND playingStatus == \(playbackStatus.rawValue)"
        if !includeStarred {
            query += " AND keepEpisode == 0"
        }

        return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
    }

    private class func allBufferedEpisodes() -> [Episode] {
        let query = "episodeStatus == \(DownloadStatus.downloadedForStreaming.rawValue) ORDER BY lastPlaybackInteractionDate DESC"

        return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
    }

    private class func deleteFilesForEpisode(_ episode: BaseEpisode) {
        let downloadManager = DownloadManager.shared
        let fileManager = FileManager.default

        // remove the download file
        do {
            try fileManager.removeItem(atPath: downloadManager.pathForEpisode(episode))
        } catch {}

        // remove any cached bufferring file
        do {
            try fileManager.removeItem(atPath: downloadManager.streamingBufferPathForEpisode(episode))
        } catch {}

        // and any temporary file in case that exists too
        do {
            try fileManager.removeItem(atPath: downloadManager.tempPathForEpisode(episode))
        } catch {}
    }

    class func removeDownloadForEpisodes(_ episodes: [BaseEpisode]) {
        var episodesToRemoveFromQueue = episodes
        if let currentEpisode = PlaybackManager.shared.currentEpisode(), let index = episodes.firstIndex(where: { $0.uuid == currentEpisode.uuid }) {
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: currentEpisode, fireNotification: true, saveCurrentEpisode: true)
            episodesToRemoveFromQueue.remove(at: index)
        }
        let uuids = episodesToRemoveFromQueue.map(\.uuid)
        PlaybackManager.shared.bulkRemoveQueued(uuids: uuids)
        var userEpisodeUuidsToDelete = [String]()
        var episodesToMarkAsNotDownloaded = [BaseEpisode]()
        for episode in episodes {
            deleteFilesForEpisode(episode)
            if let userEpisode = episode as? UserEpisode, !userEpisode.uploaded() {
                userEpisodeUuidsToDelete.append(userEpisode.uuid)
            } else {
                episodesToMarkAsNotDownloaded.append(episode)
            }
        }

        // If user episodes are only downloaded on this device delete them
        DataManager.sharedManager.deleteUserEpisodes(userEpisodeUuids: userEpisodeUuidsToDelete)
        DataManager.sharedManager.bulkUserFileDelete(baseEpisodes: episodesToMarkAsNotDownloaded)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)

        analyticsHelper.bulkDeleteDownloadedEpisodes(count: episodesToRemoveFromQueue.count)
    }
}
