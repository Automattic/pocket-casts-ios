import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

extension SyncTask {
    func changedPodcasts() -> [Api_Record]? {
        let podcastsToSync = DataManager.sharedManager.allUnsyncedPodcasts()

        if podcastsToSync.count == 0 { return nil }

        var podcastRecords = [Api_Record]()
        for podcast in podcastsToSync {
            var podcastRecord = Api_SyncUserPodcast()
            podcastRecord.autoStartFrom.value = podcast.startFrom
            podcastRecord.autoSkipLast.value = podcast.skipLast
            podcastRecord.uuid = podcast.uuid
            podcastRecord.isDeleted.value = !podcast.isSubscribed()
            podcastRecord.subscribed.value = podcast.isSubscribed()
            podcastRecord.sortPosition.value = podcast.sortOrder

            if FeatureFlag.settingsSync.enabled {
                podcastRecord.settings = podcast.apiSettings
            }

            // There's a bug on the watch app that resets all users folders
            // Since the watch don't use folders at all, it shouldn't sync
            #if !os(watchOS)
            podcastRecord.folderUuid.value = podcast.folderUuid ?? DataConstants.homeGridFolderUuid
            #endif

            if let addedDate = podcast.addedDate {
                podcastRecord.dateAdded = Google_Protobuf_Timestamp(date: addedDate)
            }

            FileLog.shared.addMessage("Syncing new settings for \(podcastRecord.uuid): \(try! podcastRecord.settings.jsonString())")

            var apiRecord = Api_Record()
            apiRecord.podcast = podcastRecord
            podcastRecords.append(apiRecord)
        }

        return podcastRecords
    }

    func changedEpisodes(for episodesToSync: [Episode]) -> [Api_Record]? {
        if episodesToSync.count == 0 { return nil }

        var episodeRecords = [Api_Record]()
        for episode in episodesToSync {
            var episodeRecord = Api_SyncUserEpisode()
            episodeRecord.podcastUuid = episode.podcastUuid
            episodeRecord.uuid = episode.uuid

            if episode.playingStatusModified > 0 {
                episodeRecord.playingStatus.value = episode.playingStatus
                episodeRecord.playingStatusModified.value = episode.playingStatusModified
            }
            if episode.keepEpisodeModified > 0 {
                episodeRecord.starred.value = episode.keepEpisode
                episodeRecord.starredModified.value = episode.keepEpisodeModified
            }
            if episode.playedUpToModified > 0 {
                episodeRecord.playedUpTo.value = Int64(episode.playedUpTo)
                episodeRecord.playedUpToModified.value = episode.playedUpToModified
            }
            if episode.durationModified > 0, episode.duration > 0 {
                episodeRecord.duration.value = Int64(episode.duration)
                episodeRecord.durationModified.value = episode.durationModified
            }
            if episode.archivedModified > 0 {
                episodeRecord.isDeleted.value = episode.archived
                episodeRecord.isDeletedModified.value = episode.archivedModified
            }

            var apiRecord = Api_Record()
            apiRecord.episode = episodeRecord
            episodeRecords.append(apiRecord)
        }

        return episodeRecords
    }

    func changedFolders() -> [Api_Record]? {
        let foldersToSync = DataManager.sharedManager.allUnsyncedFolders()

        if foldersToSync.count == 0 { return nil }

        var folderRecords = [Api_Record]()
        for folder in foldersToSync {
            var folderRecord = Api_SyncUserFolder()
            folderRecord.folderUuid = folder.uuid
            folderRecord.color = folder.color
            folderRecord.name = folder.name
            folderRecord.isDeleted = folder.wasDeleted
            folderRecord.sortPosition = folder.sortOrder
            folderRecord.podcastsSortType = ServerConverter.convertToServerSortType(clientType: Int(folder.sortType))
            if let addedDate = folder.addedDate {
                folderRecord.dateAdded = Google_Protobuf_Timestamp(date: addedDate)
            }

            var apiRecord = Api_Record()
            apiRecord.folder = folderRecord
            folderRecords.append(apiRecord)
        }

        return folderRecords
    }

    func changedFilters() -> [Api_Record]? {
        let filtersToSync = DataManager.sharedManager.allUnsyncedFilters()

        if filtersToSync.count == 0 { return nil }

        var filterRecords = [Api_Record]()
        for filter in filtersToSync {
            var filterRecord = Api_SyncUserPlaylist()
            filterRecord.allPodcasts.value = filter.podcastUuids.count == 0
            filterRecord.uuid = filter.uuid
            filterRecord.originalUuid = filter.uuid // server side this field is important, because it will remain the same case DO NOT REMOVE
            filterRecord.isDeleted.value = filter.wasDeleted
            filterRecord.title.value = filter.playlistName
            filterRecord.podcastUuids.value = filter.podcastUuids
            filterRecord.audioVideo.value = filter.filterAudioVideoType
            filterRecord.notDownloaded.value = filter.filterNotDownloaded
            filterRecord.downloaded.value = filter.filterDownloaded
            filterRecord.downloading.value = filter.filterDownloading
            filterRecord.finished.value = filter.filterFinished
            filterRecord.partiallyPlayed.value = filter.filterPartiallyPlayed
            filterRecord.unplayed.value = filter.filterUnplayed
            filterRecord.starred.value = filter.filterStarred
            filterRecord.filterHours.value = filter.filterHours
            filterRecord.sortPosition.value = filter.sortPosition
            filterRecord.sortType.value = filter.sortType
            filterRecord.iconID.value = filter.customIcon
            filterRecord.filterDuration.value = filter.filterDuration
            filterRecord.shorterThan.value = filter.shorterThan
            filterRecord.longerThan.value = filter.longerThan

            var apiRecord = Api_Record()
            apiRecord.playlist = filterRecord
            filterRecords.append(apiRecord)
        }

        return filterRecords
    }

    /// Retrieve any bookmarks that need to be sent to the server
    func changedBookmarks() -> [Api_Record]? {
        dataManager.bookmarks.bookmarksToSync()
            .map { .init(bookmark: $0) }
            .nilIfEmpty()
    }

    func changedStats() -> Api_Record? {
        let timeSavedDynamicSpeed = convertStat(StatsManager.shared.timeSavedDynamicSpeed())
        let totalSkippedTime = convertStat(StatsManager.shared.totalSkippedTime())
        let totalIntroSkippedTime = convertStat(StatsManager.shared.totalAutoSkippedTime())
        let timeSavedVariableSpeed = convertStat(StatsManager.shared.timeSavedVariableSpeed())
        let totalListeningTime = convertStat(StatsManager.shared.totalListeningTime())
        let startSyncTime = Int64(StatsManager.shared.statsStartDate().timeIntervalSince1970)

        // check to see if there's actually any stats we need to sync
        if StatsManager.shared.syncStatus() != .notSynced || (timeSavedDynamicSpeed == nil && totalSkippedTime == nil && totalSkippedTime == nil && timeSavedVariableSpeed == nil && totalListeningTime == nil) {
            return nil
        }

        var deviceRecord = Api_SyncUserDevice()
        deviceRecord.timeSilenceRemoval.value = timeSavedDynamicSpeed ?? 0
        deviceRecord.timeSkipping.value = totalSkippedTime ?? 0
        deviceRecord.timeIntroSkipping.value = totalIntroSkippedTime ?? 0
        deviceRecord.timeVariableSpeed.value = timeSavedVariableSpeed ?? 0
        deviceRecord.timeListened.value = totalListeningTime ?? 0
        deviceRecord.timesStartedAt.value = startSyncTime
        deviceRecord.deviceID.value = ServerConfig.shared.syncDelegate?.uniqueAppId() ?? ""
        deviceRecord.deviceType.value = ServerConstants.Values.deviceTypeiOS

        var apiRecord = Api_Record()
        apiRecord.device = deviceRecord

        return apiRecord
    }

    private func convertStat(_ stat: TimeInterval) -> Int64? {
        if stat < 1 { return nil }

        return Int64(stat)
    }
}

// MARK: - Bookmark Helpers

private extension Api_Record {
    init(bookmark: Bookmark) {
        self.init()

        self.bookmark = .init(bookmark: bookmark)
    }
}

private extension Api_SyncUserBookmark {
    init(bookmark: Bookmark) {
        self.init()

        self.bookmarkUuid = bookmark.uuid
        self.episodeUuid = bookmark.episodeUuid
        self.podcastUuid = bookmark.podcastUuid ?? DataConstants.userEpisodeFakePodcastId
        self.time.value = .init(bookmark.time)
        self.createdAt = .init(date: bookmark.created)

        self.isDeleted.value = bookmark.deleted
        self.isDeletedModified = .init(date: bookmark.deletedModified ?? bookmark.created)

        self.title.value = bookmark.title
        self.titleModified = .init(date: bookmark.titleModified ?? bookmark.created)
    }
}

// MARK: Settings Sync

private extension Podcast {
    var apiSettings: Api_PodcastSettings {
        var settings = Api_PodcastSettings()
        settings.playbackEffects.update(self.settings.$customEffects)
        settings.autoStartFrom.update(self.settings.$autoStartFrom)
        settings.autoSkipLast.update(self.settings.$autoSkipLast)
        settings.playbackSpeed.update(self.settings.$playbackSpeed)
        settings.trimSilence.update(self.settings.$trimSilence)
        settings.volumeBoost.update(self.settings.$boostVolume)
        settings.addToUpNext.update(self.settings.$addToUpNext)
        settings.addToUpNextPosition.update(self.settings.$addToUpNextPosition)
        settings.episodesSortOrder.update(self.settings.$episodesSortOrder)
        settings.episodeGrouping.update(self.settings.$episodeGrouping)
        settings.autoArchive.update(self.settings.$autoArchive)
        settings.autoArchivePlayed.update(self.settings.$autoArchivePlayed)
        settings.autoArchiveInactive.update(self.settings.$autoArchiveInactive)
        settings.autoArchiveEpisodeLimit.update(self.settings.$autoArchiveEpisodeLimit)
        return settings
    }
}

extension SwiftProtobuf.Google_Protobuf_Int64Value {
    init(date: Date) {
        self.init()

        // The server uses `Instant.ofEpochMilli` when converting the date which expects the time value to be in
        // milliseconds. So we'll * 1000 to convert the time stamp
        self.value = .init(date.timeIntervalSince1970 * 1000)
    }
}
