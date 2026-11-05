import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension SyncTask {
    func processServerPlaylists(_ playlists: [(EpisodeFilter, [Episode])]) {
        // before looking at the server playlists, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.shared.markAllPlaylistsUnsynced()

        playlists.forEach { playlist, serverEpisodes in
            // if we have this playlist locally, assume the server version is more up to date, so blow ours away
            if let localPlaylist = DataManager.shared.findPlaylist(uuid: playlist.uuid) {
                DataManager.shared.delete(playlist: localPlaylist)
            }

            // save the server version of the filter, as long as it's not deleted
            guard !playlist.wasDeleted else {
                return
            }

            var addedEpisodes: [Episode] = []

            // Add missing episodes
            let matchedEpisodeUuids = Set(DataManager.shared.playlistEpisodes(for: playlist).map { $0.uuid })
            addedEpisodes = serverEpisodes.filter { !matchedEpisodeUuids.contains($0.uuid) }

            playlist.syncStatus = SyncStatus.synced.rawValue
            DataManager.shared.save(playlist: playlist)
            let didAdd = DataManager.shared.add(episodes: addedEpisodes, to: playlist)
            if !didAdd {
                let playlistCount = DataManager.shared.allPlaylistEpisodeCount(for: playlist, episodeUuidToAdd: nil, includingArchivedEpisodes: true)
                FileLog.shared.addMessage("SyncTask: Tried to add too many episodes from server playlist \(playlist.playlistName) episodeCount: \(addedEpisodes) playlistCount: \(playlistCount)")
            }
        }
    }

    func processServerHomeGrid(podcasts: [PodcastSyncInfo]?, folders: [FolderSyncInfo]?, lastSyncAt: String) {
        // before looking at the server podcasts, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.shared.markAllPodcastsUnsyncedWhereLastSyncAtNot(lastSyncAt)

        // for folders we take the opposite approach, anything you currently have on device is old and should be replaced with the server copy
        DataManager.shared.clearAllFolderInformation()

        // import any folders first, since that's fast and needs no extra calls
        if let folders {
            for folder in folders {
                processFolder(folder)
            }
        }

        guard let podcasts else { return }

        totalToImport = podcasts.count
        NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastCount, object: totalToImport)

        let retrievesEpisodeStateBeforeAdding = FeatureFlag.fullSyncEpisodeStateOffInsertQueue.enabled
        upToPodcast = 0
        for podcast in podcasts {
            importQueue.addOperation {
                self.upToPodcast += 1
                NotificationCenter.default.post(name: ServerNotifications.syncProgressPodcastUpto, object: self.upToPodcast)

                self.processPodcast(podcast, lastSyncAt: lastSyncAt, retrievesEpisodeStateBeforeAdding: retrievesEpisodeStateBeforeAdding)
            }
        }
        importQueue.waitUntilAllOperationsAreFinished()

        NotificationCenter.default.post(name: ServerNotifications.syncProgressImportedPodcasts, object: nil)
    }

    private func processFolder(_ folder: FolderSyncInfo) {
        FolderHelper.addFolderToDatabase(folder)
    }

    func processPodcast(_ podcast: PodcastSyncInfo, lastSyncAt: String, retrievesEpisodeStateBeforeAdding: Bool, timeout: DispatchTimeInterval = .seconds(30)) {
        guard let uuid = podcast.uuid else { return }

        if let localPodcast = DataManager.shared.findPodcast(uuid: uuid), lastSyncAt == localPodcast.fullSyncLastSyncAt {
            FileLog.shared.addMessage("Skipping processing of podcast \(uuid) in full sync, already done previously")
            return
        }

        FileLog.shared.addMessage("Processing podcast \(uuid)")

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        if retrievesEpisodeStateBeforeAdding {
            CacheServerHandler.shared.loadPodcastInfo(podcastUuid: uuid) { podcastInfo, lastModified in
                guard let podcastInfo else {
                    dispatchGroup.leave()
                    return
                }

                self.episodeStateQueue.addOperation {
                    let episodes = self.retrieveEpisodeSyncInfo(podcastUuid: uuid)
                    ServerPodcastManager.shared.addFromJson(podcastUuid: uuid, lastModified: lastModified, podcastInfo: podcastInfo, subscribe: true, autoDownloads: 0) { added in
                        if added {
                            self.saveSyncInfo(podcast, uuid: uuid, lastSyncAt: lastSyncAt, episodeSyncInfo: episodes)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        } else {
            ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true) { added in
                if added {
                    let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: uuid)
                    self.saveSyncInfo(podcast, uuid: uuid, lastSyncAt: lastSyncAt, episodeSyncInfo: episodes)
                }
                dispatchGroup.leave()
            }
        }

        _ = dispatchGroup.wait(timeout: .now() + timeout)
    }

    private func retrieveEpisodeSyncInfo(podcastUuid: String) -> [EpisodeSyncInfo]? {
        if let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: podcastUuid) {
            return episodes
        }

        FileLog.shared.addMessage("SyncTask: Retrying the episode state request for podcast \(podcastUuid)")
        return ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: podcastUuid)
    }

    private func saveSyncInfo(_ podcast: PodcastSyncInfo, uuid: String, lastSyncAt: String, episodeSyncInfo episodes: [EpisodeSyncInfo]?) {
        guard let localPodcast = DataManager.shared.findPodcast(uuid: uuid) else {
            FileLog.shared.addMessage("SyncTask: Added podcast \(uuid) but couldn't find it to save its sync info")
            return
        }

        applySyncInfo(podcast, lastSyncAt: lastSyncAt, to: localPodcast)
        DataManager.shared.save(podcast: localPodcast)

        guard let episodes else {
            FileLog.shared.addMessage("SyncTask: Couldn't retrieve the episode state for podcast \(uuid)")
            return
        }

        DataManager.shared.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
    }

    private func applySyncInfo(_ podcast: PodcastSyncInfo, lastSyncAt: String, to localPodcast: Podcast) {
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

        localPodcast.folderUuid = podcast.folderUuid

        if let sortOrder = podcast.sortPosition {
            localPodcast.sortOrder = sortOrder
        }

        if let settings = podcast.settings {
            processSettings(settings, to: localPodcast)
        }
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
                let existingBookmark = bookmarkManager.bookmark(for: apiBookmark.bookmarkUuid, allowDeleted: true)

                if let existingBookmark {
                    await bookmarkManager.permanentlyDelete(bookmarks: [existingBookmark]).when(false) {
                        FileLog.shared.addMessage("SyncTask: Process Server Bookmarks - Could not delete existing bookmark: \(apiBookmark.bookmarkUuid)")
                    }
                }

                // Add the incoming bookmark to the database
                bookmarkManager.add(from: apiBookmark, existingBookmark: existingBookmark).when(.none) {
                    FileLog.shared.addMessage("SyncTask: Process Server Bookmarks - Could not add bookmark: \(String(describing: try? apiBookmark.jsonString()))")
                }
            }

            semaphore.signal()
        }

        semaphore.wait()
    }
}

private extension BookmarkDataManager {
    func add(from apiBookmark: Api_BookmarkResponse, existingBookmark: Bookmark?) -> String? {
        let takesServerPassage = apiBookmark.passageModifiedDate.map { $0 >= (existingBookmark?.passageModified ?? .distantPast) } ?? false
        let takesServerReferenceTime = apiBookmark.referenceTimeModifiedDate.map { $0 >= (existingBookmark?.referenceTimeModified ?? .distantPast) } ?? false

        return add(uuid: apiBookmark.bookmarkUuid,
                   episodeUuid: apiBookmark.episodeUuid,
                   podcastUuid: apiBookmark.podcastUuid == DataConstants.userEpisodeFakePodcastId ? nil : apiBookmark.podcastUuid,
                   title: apiBookmark.title,
                   time: .init(apiBookmark.time),
                   dateCreated: apiBookmark.createdAt.date,
                   passage: takesServerPassage ? apiBookmark.bookmarkPassage : existingBookmark?.passage,
                   passageLocation: takesServerPassage ? apiBookmark.bookmarkPassageLocation : existingBookmark?.passageLocation,
                   passageModified: takesServerPassage ? apiBookmark.passageModifiedDate : existingBookmark?.passageModified,
                   referenceTime: takesServerReferenceTime ? apiBookmark.bookmarkReferenceTime : existingBookmark?.referenceTime,
                   referenceTimeModified: takesServerReferenceTime ? apiBookmark.referenceTimeModifiedDate : existingBookmark?.referenceTimeModified,
                   syncStatus: .synced)
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
        podcast.settings.$addToUpNext = settings.$addToUpNext
        podcast.settings.$addToUpNextPosition = settings.$addToUpNextPosition
        podcast.settings.$episodesSortOrder = settings.$episodesSortOrder
        podcast.settings.$episodeGrouping = settings.$episodeGrouping
        podcast.settings.$showArchived = settings.$showArchived
        oldSettings.printDiff(from: podcast.settings, withIdentifier: podcast.uuid)
    }
}
