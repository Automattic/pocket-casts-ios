import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension SyncTask {
    func processServerFilters(_ filters: [EpisodeFilter]) {
        // before looking at the server filters, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.sharedManager.markAllEpisodeFiltersUnsynced()

        for filter in filters {
            // if we have this filter locally, assume the server version is more up to date, so blow ours away
            if let localFilter = DataManager.sharedManager.findFilter(uuid: filter.uuid) {
                DataManager.sharedManager.delete(filter: localFilter)
            }

            // save the server version of the filter, as long as it's not deleted
            if !filter.wasDeleted {
                filter.syncStatus = SyncStatus.synced.rawValue
                DataManager.sharedManager.save(filter: filter)
            }
        }
    }

    func processServerHomeGrid(podcasts: [PodcastSyncInfo]?, folders: [FolderSyncInfo]?, lastSyncAt: String) {
        // before looking at the server podcasts, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.sharedManager.markAllPodcastsUnsyncedWhereLastSyncAtNot(lastSyncAt)

        // for folders we take the opposite approach, anything you currently have on device is old and should be replaced with the server copy
        DataManager.sharedManager.clearAllFolderInformation()

        // import any folders first, since that's fast and needs no extra calls
        if let folders = folders {
            for folder in folders {
                processFolder(folder)
            }
        }

        guard let podcasts = podcasts else { return }

        totalToImport = podcasts.count
        NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastCount, object: totalToImport)

        upToPodcast = 0
        for podcast in podcasts {
            importQueue.addOperation {
                self.upToPodcast += 1
                NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastUpto, object: self.upToPodcast)

                self.processPodcast(podcast, lastSyncAt: lastSyncAt)
            }
        }
        importQueue.waitUntilAllOperationsAreFinished()

        NotificationCenter.default.post(name: ServerNotifications.syncProgressImportedPodcasts, object: nil)
    }

    private func processFolder(_ folder: FolderSyncInfo) {
        FolderHelper.addFolderToDatabase(folder)
    }

    func processPodcast(_ podcast: PodcastSyncInfo, lastSyncAt: String) {
        guard let uuid = podcast.uuid else { return }

        if let localPodcast = DataManager.sharedManager.findPodcast(uuid: uuid), lastSyncAt == localPodcast.fullSyncLastSyncAt {
            FileLog.shared.addMessage("Skipping processing of podcast \(uuid) in full sync, already done previously")
            return
        }

        FileLog.shared.addMessage("Processing podcast \(uuid)")
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true) { success in
            if !success {
                dispatchGroup.leave()

                return
            }

            guard let localPodcast = DataManager.sharedManager.findPodcast(uuid: uuid) else { return }

            // we have added the podcast locally so add the synced info for it
            if let startFrom = podcast.autoStartFrom {
                localPodcast.startFrom = Int32(startFrom)
            }
            if let skipLast = podcast.autoSkipLast {
                localPodcast.skipLast = Int32(skipLast)
            }
            localPodcast.syncStatus = SyncStatus.synced.rawValue
            localPodcast.fullSyncLastSyncAt = lastSyncAt

            if let addedDate = podcast.dateAdded {
                localPodcast.addedDate = addedDate
            }

            FileLog.shared.foldersIssue("SyncTask processPodcast: changing \(localPodcast.title ?? "") folder from \(localPodcast.folderUuid ?? "nil") to \(podcast.folderUuid ?? "nil")")
            localPodcast.folderUuid = podcast.folderUuid

            if let sortOrder = podcast.sortPosition {
                localPodcast.sortOrder = sortOrder
            }

            if let settings = podcast.settings {
                self.processSettings(settings, to: localPodcast)
            }

            // now grab the sync info for the episodes
            let retrieveEpisodesTask = RetrieveEpisodesTask(podcastUuid: uuid)
            retrieveEpisodesTask.completion = { episodes in
                DataManager.sharedManager.save(podcast: localPodcast)

                guard let episodes = episodes else { return }

                DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
            }
            retrieveEpisodesTask.runTaskSynchronously()
            dispatchGroup.leave()
        }

        _ = dispatchGroup.wait(timeout: .now() + 30.seconds)
    }
}

// MARK: - Bookmarks

extension SyncTask {
    /// Fully imports the server bookmarks and replaces the existing data if there is any available
    func processServerBookmarks(_ bookmarks: [Api_BookmarkResponse]) {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            let bookmarkManager = dataManager.bookmarks

            // Set all the bookmarks as synced
            await bookmarkManager.markAllBookmarksAsSynced()

            for apiBookmark in bookmarks {
                await bookmarkManager.remove(apiBookmark: apiBookmark).when(false) {
                    FileLog.shared.addMessage("SyncTask: Process Server Bookmarks - Could not delete existing bookmark: \(apiBookmark.bookmarkUuid)")
                }

                // Add the incoming bookmark to the database
                bookmarkManager.add(from: apiBookmark).when(.none) {
                    FileLog.shared.addMessage("SyncTask: Process Server Bookmarks - Could not add bookmark: \(String(describing: try? apiBookmark.jsonString()))")
                }
            }

            semaphore.signal()
        }

        semaphore.wait()
    }
}

private extension BookmarkDataManager {
    func add(from apiBookmark: Api_BookmarkResponse) -> String? {
        add(uuid: apiBookmark.bookmarkUuid,
            episodeUuid: apiBookmark.episodeUuid,
            podcastUuid: apiBookmark.podcastUuid,
            title: apiBookmark.title,
            time: .init(apiBookmark.time),
            dateCreated: apiBookmark.createdAt.date,
            syncStatus: .synced)
    }

    func remove(apiBookmark: Api_BookmarkResponse) async -> Bool? {
        guard let bookmark = bookmark(for: apiBookmark.bookmarkUuid, allowDeleted: true) else {
            return nil
        }

        return await permanentlyDelete(bookmarks: [bookmark])
    }
}

// MARK: - Settings

private extension SyncTask {
    func processSettings(_ settings: PodcastSettings, to podcast: Podcast) {
        let oldSettings = podcast.settings
        podcast.settings.$customEffects = settings.$customEffects
        podcast.settings.$autoStartFrom = settings.$autoStartFrom
        podcast.settings.$autoSkipLast = settings.$autoSkipLast
        podcast.settings.$trimSilence = settings.$trimSilence
        podcast.settings.$playbackSpeed = settings.$playbackSpeed
        podcast.settings.$boostVolume = settings.$boostVolume
        podcast.settings.$notification = settings.$notification
        podcast.settings.$autoArchive = settings.$autoArchive
        podcast.settings.$autoArchivePlayed = settings.$autoArchivePlayed
        podcast.settings.$autoArchiveInactive = settings.$autoArchiveInactive
        podcast.settings.$autoArchiveEpisodeLimit = settings.$autoArchiveEpisodeLimit
        oldSettings.printDiff(from: podcast.settings, withIdentifier: podcast.uuid)
    }
}
