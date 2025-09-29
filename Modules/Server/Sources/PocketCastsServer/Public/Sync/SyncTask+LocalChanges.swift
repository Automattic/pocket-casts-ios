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
            if let deselectedChapters = episode.deselectedChapters {
                episodeRecord.deselectedChapters = deselectedChapters
                episodeRecord.deselectedChaptersModified.value = episode.deselectedChaptersModified
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

    func changedPlaylists() -> [Api_Record]? {
        let playlistsToSync = DataManager.sharedManager.allUnsyncedPlaylists()

        if playlistsToSync.count == 0 { return nil }

        var playlistRecords = [Api_Record]()
        for playlist in playlistsToSync {
            let syncPlaylist = createSyncUserPlaylist(from: playlist)

            var apiRecord = Api_Record()
            apiRecord.playlist = syncPlaylist
            playlistRecords.append(apiRecord)
        }

        return playlistRecords
    }

    private func createSyncUserPlaylist(from filter: EpisodeFilter) -> Api_SyncUserPlaylist {
        var playlistRecord = Api_SyncUserPlaylist()
        playlistRecord.allPodcasts.value = filter.podcastUuids.count == 0
        playlistRecord.uuid = filter.uuid
        playlistRecord.originalUuid = filter.uuid // server side this field is important, because it will remain the same case DO NOT REMOVE
        playlistRecord.isDeleted.value = filter.wasDeleted
        playlistRecord.title.value = filter.playlistName
        playlistRecord.podcastUuids.value = filter.podcastUuids
        playlistRecord.audioVideo.value = filter.filterAudioVideoType
        playlistRecord.notDownloaded.value = filter.filterNotDownloaded
        playlistRecord.downloaded.value = filter.filterDownloaded
        playlistRecord.downloading.value = filter.filterDownloading
        playlistRecord.finished.value = filter.filterFinished
        playlistRecord.partiallyPlayed.value = filter.filterPartiallyPlayed
        playlistRecord.unplayed.value = filter.filterUnplayed
        playlistRecord.starred.value = filter.filterStarred
        playlistRecord.filterHours.value = filter.filterHours
        playlistRecord.sortPosition.value = filter.sortPosition
        playlistRecord.sortType.value = filter.sortType
        playlistRecord.iconID.value = filter.customIcon
        playlistRecord.filterDuration.value = filter.filterDuration
        playlistRecord.shorterThan.value = filter.shorterThan
        playlistRecord.longerThan.value = filter.longerThan
        playlistRecord.manual.value = filter.manual

        if filter.manual {
            let episodes = DataManager.sharedManager.playlistEpisodes(for: filter)
            playlistRecord.episodes = episodes.map { episode in
                createSyncEpisode(from: episode)
            }
            playlistRecord.episodeOrder = episodes.map { $0.uuid }
        }
        return playlistRecord
    }

    private func createSyncEpisode(from episode: Episode) -> Api_SyncPlaylistEpisode {
        var playlistEpisode = Api_SyncPlaylistEpisode()
        playlistEpisode.episode = episode.uuid
        playlistEpisode.podcast = episode.parentIdentifier()

        if let addedDate = episode.addedDate {
            playlistEpisode.added = Google_Protobuf_Int64Value(date: addedDate)
        }

        if let publishedDate = episode.publishedDate {
            playlistEpisode.published = Google_Protobuf_Timestamp(date: publishedDate)
        }

        if let title = episode.title, !title.isEmpty {
            playlistEpisode.title.value = title
        }

        if let url = episode.downloadUrl, !url.isEmpty {
            playlistEpisode.url.value = url
        }

        return playlistEpisode
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
        settings.notification.update(self.settings.$notification)
        settings.addToUpNext.update(self.settings.$addToUpNext)
        settings.addToUpNextPosition.update(self.settings.$addToUpNextPosition)
        settings.episodesSortOrder.update(self.settings.$episodesSortOrder)
        settings.episodeGrouping.update(self.settings.$episodeGrouping)
        settings.showArchived.update(self.settings.$showArchived)
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
