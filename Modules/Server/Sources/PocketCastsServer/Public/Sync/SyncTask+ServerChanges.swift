import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension SyncTask {
    func processServerData(response: Api_SyncUpdateResponse) {
        var podcastsToImport = [Api_SyncUserPodcast]()
        var episodesToImport = [Api_SyncUserEpisode]()
        var filtersToImport = [Api_SyncUserPlaylist]()
        var foldersToImport = [Api_SyncUserFolder]()
        var bookmarksToImport = [Api_SyncUserBookmark]()

        for item in response.records {
            guard let oneOf = item.record else { continue }

            switch oneOf {
            case .podcast:
                podcastsToImport.append(item.podcast)
            case .episode:
                episodesToImport.append(item.episode)
            case .playlist:
                filtersToImport.append(item.playlist)
            case .folder:
                foldersToImport.append(item.folder)
            case .bookmark:
                bookmarksToImport.append(item.bookmark)
            case .device:
                continue // we aren't expecting the server to send us devices
            }
        }

        totalToImport = podcastsToImport.count
        NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastCount, object: totalToImport)
        upToPodcast = 1

        // The sync order here is important. Folders need to be added before podcasts, because podcasts have folderUuids in them. Podcasts are next so we can load any episodes we don't have and then read their sync data.
        for folderItem in foldersToImport {
            importQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.importFolder(folderItem)
            }
        }

        for podcastItem in podcastsToImport {
            importQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.importPodcast(podcastItem)
            }
        }
        importQueue.waitUntilAllOperationsAreFinished()
        NotificationCenter.default.post(name: ServerNotifications.syncProgressImportedPodcasts, object: nil)

        for episodeItem in episodesToImport {
            importQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.importEpisode(episodeItem)
            }
        }

        for filterItem in filtersToImport {
            importQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.importFilter(filterItem)
            }
        }

        FileLog.shared.addMessage("SyncTask: Found \(bookmarksToImport.count) bookmarks to import")

        for bookmark in bookmarksToImport {
            importQueue.addOperation { [weak self] in
                guard let strongSelf = self else { return }
                let semaphore = DispatchSemaphore(value: 0)

                Task {
                    await strongSelf.importBookmark(bookmark)
                    semaphore.signal()
                }

                semaphore.wait()
            }
        }

        importQueue.waitUntilAllOperationsAreFinished()
    }

    private func importPodcast(_ podcastItem: Api_SyncUserPodcast) {
        let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcastItem.uuid, includeUnsubscribed: true)
        if podcastItem.hasIsDeleted, podcastItem.isDeleted.value {
            if let podcast = existingPodcast {
                podcast.autoDownloadSetting = AutoDownloadSetting.off.rawValue
                podcast.pushEnabled = false
                podcast.autoArchiveEpisodeLimit = 0
                podcast.subscribed = 0
                podcast.autoAddToUpNext = AutoAddToUpNextSetting.off.rawValue
                podcast.processSettings(podcastItem.settings)

                DataManager.sharedManager.save(podcast: podcast)
            }
        } else if let podcast = existingPodcast {
            importItem(podcastItem: podcastItem, into: podcast, checkIsDeleted: true)
            DataManager.sharedManager.save(podcast: podcast)

            ServerConfig.shared.syncDelegate?.podcastUpdated(podcastUuid: podcast.uuid)
        } else {
            let semaphore = DispatchSemaphore(value: 0)

            ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastItem.uuid, subscribe: true, completion: { success in
                if success {
                    if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastItem.uuid, includeUnsubscribed: true) {
                        podcast.syncStatus = SyncStatus.synced.rawValue
                        self.importItem(podcastItem: podcastItem, into: podcast, checkIsDeleted: false)

                        DataManager.sharedManager.save(podcast: podcast)
                    }
                }

                semaphore.signal()
            })
            _ = semaphore.wait(timeout: .distantFuture)
        }

        NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastUpto, object: upToPodcast)
        NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastCount, object: totalToImport)
        upToPodcast += 1
    }

    private func importItem(podcastItem: Api_SyncUserPodcast, into podcast: Podcast, checkIsDeleted: Bool) {
        if podcastItem.hasAutoStartFrom {
            podcast.startFrom = podcastItem.autoStartFrom.value
        }
        if podcastItem.hasAutoSkipLast {
            podcast.skipLast = podcastItem.autoSkipLast.value
        }
        if podcastItem.hasFolderUuid {
            let folderUuid = podcastItem.folderUuid.value

            FileLog.shared.foldersIssue("SyncTask importItem: \(podcast.title ?? "") changing folder from \(podcast.folderUuid ?? "nil") to \(((folderUuid == DataConstants.homeGridFolderUuid) ? nil : folderUuid) ?? "nil")")

            podcast.folderUuid = (folderUuid == DataConstants.homeGridFolderUuid) ? nil : folderUuid
        }
        if podcastItem.hasSortPosition {
            podcast.sortOrder = podcastItem.sortPosition.value
        }

        if checkIsDeleted, podcastItem.hasIsDeleted {
            podcast.subscribed = podcastItem.isDeleted.value ? 0 : 1
        }

        podcast.processSettings(podcastItem.settings)
    }

    private func importEpisode(_ episodeItem: Api_SyncUserEpisode) {
        var existingEpisode = DataManager.sharedManager.findEpisode(uuid: episodeItem.uuid)

        if existingEpisode == nil {
            // we don't have this episode so try and find it
            FileLog.shared.addMessage("Trying to find missing episode as part of a sync \(episodeItem.uuid)")
            existingEpisode = ServerPodcastManager.shared.addMissingEpisode(episodeUuid: episodeItem.uuid, podcastUuid: episodeItem.podcastUuid)
        }

        guard let episode = existingEpisode else { return }

        if episodeItem.hasStarred, episode.keepEpisode != episodeItem.starred.value {
            let updateSaved = DataManager.sharedManager.saveIfNotModified(starred: episodeItem.starred.value, episodeUuid: episode.uuid)
            if updateSaved {
                ServerConfig.shared.syncDelegate?.episodeStarredChanged(episode: episode)
            }
        }

        // The order of the two methods below is important, we should always archive an episode if it's been archived before marking it as played.
        // This is because marking something as played has the potential to archive it as well, but doing so on device will update the time it was done potentially causing sync issues

        if episodeItem.hasIsDeleted, episode.archived != episodeItem.isDeleted.value {
            if isPlayerPlaying(episode: episode) {
                // if we're actively playing this episode, mark the archive status as unsynced because ours is considered more current
                DataManager.sharedManager.saveEpisode(archived: false, episode: episode, updateSyncFlag: true)
            } else {
                if episodeItem.isDeleted.value {
                    ServerConfig.shared.syncDelegate?.archiveEpisodeExternal(episode: episode)
                } else {
                    _ = DataManager.sharedManager.saveIfNotModified(archived: false, episodeUuid: episode.uuid)
                }
            }
        }

        if episodeItem.hasPlayingStatus, episode.playingStatus != episodeItem.playingStatus.value {
            if isPlayerPlaying(episode: episode) {
                // if we're actively playing this episode, mark the status as unsynced because ours is considered more current
                DataManager.sharedManager.saveEpisode(playingStatus: .inProgress, episode: episode, updateSyncFlag: true)
            } else {
                let playingStatus = PlayingStatus(rawValue: episodeItem.playingStatus.value) ?? PlayingStatus.notPlayed
                let updateSaved = DataManager.sharedManager.saveIfNotModified(playingStatus: playingStatus, episodeUuid: episode.uuid)
                if updateSaved, playingStatus == .completed {
                    // if an episode has been marked as played on one device, give it the same treatment on this one, including deletions, etc
                    ServerConfig.shared.syncDelegate?.markEpisodeAsPlayedExternal(episode: episode)
                }
            }
        }

        if episodeItem.hasPlayedUpTo, Int64(episode.playedUpTo) != episodeItem.playedUpTo.value {
            let playedUpTo = Double(episodeItem.playedUpTo.value)
            DataManager.sharedManager.saveEpisode(playedUpTo: playedUpTo, episode: episode, updateSyncFlag: false)

            // if the episode is loaded into the player, and is currently paused seek to the new up to time
            if let delegate = ServerConfig.shared.playbackDelegate, delegate.isNowPlayingEpisode(episodeUuid: episode.uuid), !delegate.playing() {
                if playedUpTo < 1 {
                    FileLog.shared.addMessage("Saving a time of \(playedUpTo) for episode \(episode.displayableTitle()) because that's what the server sent us during a sync")
                }
                ServerConfig.shared.playbackDelegate?.seekToFromSync(time: playedUpTo, syncChanges: false, startPlaybackAfterSeek: false)
            }
        }

        // only update the duration if we aren't actively playing this episode
        if episodeItem.hasDuration, Int64(episode.duration) != episodeItem.duration.value, !isPlayerPlaying(episode: episode) {
            DataManager.sharedManager.saveEpisode(duration: Double(episodeItem.duration.value), episode: episode, updateSyncFlag: false)
        }
    }

    private func importFolder(_ folderItem: Api_SyncUserFolder) {
        let folderUuid = folderItem.folderUuid

        // if another device has deleted this folder, we need to delete it as well. No point in importing any of it's properties, so we return here as well
        if folderItem.isDeleted {
            DataManager.sharedManager.delete(folderUuid: folderUuid, markAsDeleted: false)
            FileLog.shared.foldersIssue("SyncTask importFolder: delete folder \(folderUuid)")

            return
        }

        var existingFolder = DataManager.sharedManager.findFolder(uuid: folderUuid)
        if existingFolder == nil {
            existingFolder = Folder()
            existingFolder?.uuid = folderUuid
        }
        guard let folder = existingFolder else { return }

        folder.name = folderItem.name
        folder.color = folderItem.color
        folder.sortOrder = folderItem.sortPosition
        folder.sortType = Int32(ServerConverter.convertToClientSortType(serverType: folderItem.podcastsSortType))
        folder.addedDate = folderItem.dateAdded.date

        DataManager.sharedManager.save(folder: folder)
    }

    private func importFilter(_ filterItem: Api_SyncUserPlaylist) {
        let filterUuid = filterItem.originalUuid // it's important to use this field, not uuid because the server won't change the case on this one
        var existingFilter = DataManager.sharedManager.findFilter(uuid: filterUuid)

        // if the filter exists, and another device has deleted it, then delete it
        if filterItem.hasIsDeleted, filterItem.isDeleted.value {
            if let filter = existingFilter {
                DataManager.sharedManager.delete(filter: filter)
            }

            return
        }

        if filterItem.hasManual, filterItem.manual.value {
            return // we don't support manual filters
        }

        if existingFilter == nil {
            existingFilter = EpisodeFilter()
            existingFilter?.uuid = filterUuid
        }

        guard let filter = existingFilter else { return }

        filter.wasDeleted = false
        filter.syncStatus = SyncStatus.synced.rawValue
        if filterItem.hasTitle {
            filter.playlistName = filterItem.title.value
        }
        if filterItem.hasAllPodcasts {
            filter.filterAllPodcasts = filterItem.allPodcasts.value
        }
        if filterItem.hasAudioVideo {
            filter.filterAudioVideoType = filterItem.audioVideo.value
        }
        if filterItem.hasNotDownloaded {
            filter.filterNotDownloaded = filterItem.notDownloaded.value
        }
        if filterItem.hasDownloaded {
            filter.filterDownloaded = filterItem.downloaded.value
        }
        if filterItem.hasFinished {
            filter.filterFinished = filterItem.finished.value
        }
        if filterItem.hasPartiallyPlayed {
            filter.filterPartiallyPlayed = filterItem.partiallyPlayed.value
        }
        if filterItem.hasUnplayed {
            filter.filterUnplayed = filterItem.unplayed.value
        }
        if filterItem.hasStarred {
            filter.filterStarred = filterItem.starred.value
        }
        if filterItem.hasSortPosition {
            filter.sortPosition = filterItem.sortPosition.value
        }
        if filterItem.hasSortType {
            filter.sortType = filterItem.sortType.value
        }
        if filterItem.hasIconID {
            filter.customIcon = filterItem.iconID.value
        }
        if filterItem.hasFilterHours {
            filter.filterHours = filterItem.filterHours.value
        }
        if filterItem.hasFilterDuration {
            filter.filterDuration = filterItem.filterDuration.value
        }
        if filterItem.hasShorterThan {
            filter.shorterThan = filterItem.shorterThan.value
        }
        if filterItem.hasLongerThan {
            filter.longerThan = filterItem.longerThan.value
        }

        if filterItem.hasPodcastUuids {
            filter.podcastUuids = filterItem.podcastUuids.value
        } else {
            filter.podcastUuids = ""
        }

        DataManager.sharedManager.save(filter: filter)
    }

    func isPlayerPlaying(episode: Episode) -> Bool {
        ServerConfig.shared.playbackDelegate?.isActivelyPlaying(episodeUuid: episode.uuid) ?? false
    }

    func importBookmark(_ apiBookmark: Api_SyncUserBookmark) async {
        let bookmarkManager = dataManager.bookmarks

        // Add the bookmark if it's not in the database
        guard let existingBookmark = bookmarkManager.bookmark(for: apiBookmark.bookmarkUuid, allowDeleted: true) else {
            if !apiBookmark.shouldDelete {
                // If the podcast is for a user episode then we default to nil
                let podcastUuid = apiBookmark.podcastUuid == DataConstants.userEpisodeFakePodcastId ? nil : apiBookmark.podcastUuid

                let addedUuid = bookmarkManager.add(uuid: apiBookmark.bookmarkUuid,
                                                    episodeUuid: apiBookmark.episodeUuid,
                                                    podcastUuid: podcastUuid,
                                                    title: apiBookmark.title.value,
                                                    time: Double(apiBookmark.time.value),
                                                    dateCreated: apiBookmark.createdAt.date,
                                                    syncStatus: .synced)

                if addedUuid == nil {
                    FileLog.shared.addMessage("SyncTask: Import Bookmark Failed: Could not add non existent bookmark. API data: \(apiBookmark.logDescription)")
                }
            }
            return
        }

        // Delete the bookmark
        // Using an if to make it more explicit
        if apiBookmark.shouldDelete {
            await bookmarkManager.permanentlyDelete(bookmarks: [existingBookmark]).when(false, {
                FileLog.shared.addMessage("SyncTask: Import Bookmark Failed: Could not delete uuid: \(existingBookmark.uuid). API Data: \(apiBookmark.logDescription)")
            })
            return
        }

        // Update
        guard
            let title = apiBookmark.bookmarkTitle,
            let time = apiBookmark.bookmarkTime,
            let created = apiBookmark.created
        else {
            FileLog.shared.addMessage("SyncTask: Import Bookmark Failed: Did not update bookmark because its missing required fields. API Data: \(apiBookmark.logDescription)")
            return
        }

        await bookmarkManager.update(bookmark: existingBookmark, title: title, time: time, created: created, syncStatus: .synced).when(false) {
            FileLog.shared.addMessage("SyncTask: Update Bookmark Failed. API Data: \(apiBookmark.logDescription)")
        }
    }
}

// MARK: - Api_SyncUserBookmark Helper Extension

private extension Api_SyncUserBookmark {
    var shouldDelete: Bool {
        hasIsDeleted && isDeleted.value == true
    }

    var bookmarkTitle: String? {
        hasTitle ? title.value : nil
    }

    var bookmarkTime: TimeInterval? {
        guard hasTime else {
            return nil
        }

        let time = TimeInterval(time.value)
        return time.isNumeric ? time : nil
    }

    var created: Date? {
        hasCreatedAt ? createdAt.date : nil
    }

    var logDescription: String {
        (try? jsonString()) ?? "invalid api bookmark"
    }
}

extension Podcast {
    func processSettings(_ settings: Api_PodcastSettings) {
        self.settings.$customEffects.update(setting: settings.playbackEffects)
        self.settings.$autoStartFrom.update(setting: settings.autoStartFrom)
        self.settings.$autoSkipLast.update(setting: settings.autoSkipLast)
        self.settings.$trimSilence.update(setting: settings.trimSilence)
        self.settings.$playbackSpeed.update(setting: settings.playbackSpeed)
        self.settings.$boostVolume.update(setting: settings.volumeBoost)
    }
}
