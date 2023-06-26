import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class UpNextSyncTask: ApiBaseTask {
    private static let processDataLock = NSObject()

    override func apiTokenAcquired(token: String) {
        let trace = TraceManager.shared.beginTracing(eventName: "SERVER_UP_NEXT_SYNC")
        defer { TraceManager.shared.endTracing(trace: trace) }

        let (syncRequest, latestActionTime) = createUpNextSyncRequest()
        let url = ServerConstants.Urls.api() + "up_next/sync"
        do {
            let data = try syncRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)
            if httpStatus == ServerConstants.HttpConstants.notModified {
                // no changes that we need to process
                FileLog.shared.addMessage("UpNextSyncTask: Server returned not modified to Up Next sync, no changes required")
            } else if let response = response, httpStatus == ServerConstants.HttpConstants.ok {
                process(serverData: response, latestActionTime: latestActionTime)
            } else {
                FileLog.shared.addMessage("UpNextSyncTask: Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("UpNextSyncTask: had issues encoding protobuf \(error.localizedDescription)")
        }
    }

    func createUpNextUrlRequest(token: String) -> (urlRequest: URLRequest, latestActionTime: Int64)? {
        guard let url = URL(string: ServerConstants.Urls.api() + "up_next/sync") else { return nil }

        let protoRequest = createUpNextSyncRequest()
        do {
            let data = try protoRequest.request.serializedData()
            var request = createRequest(url: url, method: "POST", token: token)
            request.httpBody = data

            return (request, protoRequest.latestActionTime)
        } catch {}

        return nil
    }

    private func createUpNextSyncRequest() -> (request: Api_UpNextSyncRequest, latestActionTime: Int64) {
        var syncRequest = Api_UpNextSyncRequest()
        syncRequest.deviceTime = TimeFormatter.currentUTCTimeInMillis()
        syncRequest.version = apiVersion
        var upNextChanges = Api_UpNextChanges()
        var latestActionTime: Int64 = 0
        var changes = [Api_UpNextChanges.Change]()

        FileLog.shared.addMessage("UpNextSyncTask [createUpNextSyncRequest]: Sync Reason? \(SyncManager.syncReason?.rawValue ?? "None")")

        // The process for syncing the up next queue involves sending all local changes to the server, which then attempts
        // to apply those changes to the stored queue in the database. Once complete, the modified queue is saved in the
        // database and sent back to us. The changes are then applied to the local queue by the "applyServerChanges" logic.
        //
        // This works well when each device keeps up to date and tracks its own changes to the queue, but can be problematic if a user
        // signs into an existing account using a device whose queue is completely different from what is stored on the server,
        // such as a user who installs the app, adds items to their queue, and then signs into an existing account. This
        // can result in the queue being completely replaced by the new devices changes.
        //
        // To prevent this, during a login we no longer send any local changes to the server, instead we pull the latest sync'd
        // up next queue and attempt to merge the changes later in the "applyServerChanges" call.
        if SyncManager.syncReason != .login {
            // replace action
            if let replaceAction = DataManager.sharedManager.findReplaceAction() {
                if replaceAction.utcTime > latestActionTime {
                    latestActionTime = replaceAction.utcTime
                }
                if let action = convertToProto(action: replaceAction) {
                    changes.append(action)
                }
            }

            // all other add/remove actions
            let actions = DataManager.sharedManager.findUpdateActions()
            if actions.count > 0 {
                for action in actions {
                    if action.utcTime > latestActionTime {
                        latestActionTime = action.utcTime
                    }
                    if let protoAction = convertToProto(action: action) {
                        changes.append(protoAction)
                    }
                }
            }

            upNextChanges.changes = changes

            if let modified = upNextServerModified() {
                upNextChanges.serverModified = modified
            }
            syncRequest.upNext = upNextChanges
        }

        FileLog.shared.addMessage("UpNextSyncTask: Syncing Up Next, sending \(changes.count) changes, modified time \(upNextChanges.serverModified)")
        return (syncRequest, latestActionTime)
    }

    func process(serverData: Data, latestActionTime: Int64) {
        // ensure that only one thread can be processing data at once. The code below isn't thread safe, and will lead to potential issues otherwise
        objc_sync_enter(UpNextSyncTask.processDataLock)
        defer { objc_sync_exit(UpNextSyncTask.processDataLock) }

        do {
            let response = try Api_UpNextResponse(serializedData: serverData)
            applyServerChanges(episodes: response.episodes)

            // save the server last modified so we can send it back next time. For legacy compatibility this is stored as a string
            UserDefaults.standard.set("\(response.serverModified)", forKey: ServerConstants.UserDefaults.upNextServerLastModified)

            clearSyncedData(latestActionTime: latestActionTime)
        } catch {
            FileLog.shared.addMessage("UpNextSyncTask: Failed to decode server data")
        }
    }

    private func applyServerChanges(episodes: [Api_UpNextResponse.EpisodeResponse]) {
        // When a new account is being created, the server creates an empty up next queue in the database and sends that to us.
        // To ensure that the device's local copy of the queue is maintained, we ignore the incoming remote data and instead
        // save our local copy and then send it back to the server.
        let reason = SyncManager.syncReason
        if reason == .accountCreated, ServerConfig.shared.playbackDelegate?.currentEpisode() != nil {
            // if this is our first sync (eg: no server modified stored), treat our local copy as the one that should be used. This avoids issues with users getting their Up Next list wiped by the server copy
            FileLog.shared.addMessage("UpNextSyncTask: We have a local Up Next list during first sync of a new account, saving that as the most current version and overwriting server copy")

            ServerConfig.shared.playbackDelegate?.queuePersistLocalCopyAsReplace()
            return
        }

        // check that the server list doesn't exactly match our list, if it does, no need to do anything
        guard let localEpisodes = ServerConfig.shared.playbackDelegate?.allEpisodesInQueue(includeNowPlaying: true, hydrate: false) else { return }
        if localEpisodes.count == episodes.count {
            // if they are both 0, nothing to do
            if localEpisodes.count == 0 {
                FileLog.shared.addMessage("UpNextSyncTask: no local or remote episodes, no action required")
                return
            }

            var allMatch = true
            for (index, episode) in episodes.enumerated() {
                if episode.uuid != localEpisodes[index].uuid {
                    allMatch = false
                }
            }
            if allMatch {
                FileLog.shared.addMessage("UpNextSyncTask: server copy matches our copy, no action required")
                return
            }
        }

        let modifiedList = addPlayingEpisode(list: episodes)
        FileLog.shared.addMessage("UpNextSyncTask: server sent \(episodes.count) episodes, we have \(modifiedList.count), making changes")

        let episodePlayingBeforeChanges = ServerConfig.shared.playbackDelegate?.currentEpisode()
        var uuids = [String]()
        if modifiedList.count > 0 {
            for (index, episodeInfo) in modifiedList.enumerated() {
                uuids.append(episodeInfo.uuid)

                // if the episode exists in the queue already
                // move it to a new position if it's not already there
                if let existingEpisode = DataManager.sharedManager.findPlaylistEpisode(uuid: episodeInfo.uuid) {
                    FileLog.shared.addMessage("UpNextSyncTask: Found episode \(episodeInfo.uuid) in the queue already at position \(existingEpisode.episodePosition)")

                    if existingEpisode.episodePosition != Int32(index) {
                        FileLog.shared.addMessage("UpNextSyncTask: Moving existing episode \(episodeInfo.uuid) from \(existingEpisode.episodePosition) to \(index)")
                        existingEpisode.episodePosition = Int32(index)
                        DataManager.sharedManager.save(playlistEpisode: existingEpisode)
                    }
                } else {
                    FileLog.shared.addMessage("UpNextSyncTask: Incoming episode not found \(episodeInfo.uuid) in the devices queue.")

                    let newEpisode = PlaylistEpisode()
                    newEpisode.episodePosition = Int32(index)
                    newEpisode.episodeUuid = episodeInfo.uuid

                    // The incoming episode from the server is not in the queue already.
                    // The code below adds each missing episode to the queue using one of 3 checks:

                    // 1. If the new episode exists in the local database already, then just add it to the queue
                    if let localEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeInfo.uuid) {
                        FileLog.shared.addMessage("UpNextSyncTask: Episode \(localEpisode.displayableTitle()) exists in local DB, adding to the queue")
                        // we already have this episode, so all good save the Up Next item
                        newEpisode.podcastUuid = localEpisode.parentIdentifier()
                        newEpisode.title = localEpisode.displayableTitle()
                        DataManager.sharedManager.save(playlistEpisode: newEpisode)
                    }
                    // 2. If the episode is a custom episode..
                    else if episodeInfo.podcast == DataConstants.userEpisodeFakePodcastId {
                        FileLog.shared.addMessage("UpNextSyncTask: Episode \(episodeInfo.title) is a custom episode, adding to the queue")
                        // because a custom episode import task always runs before an Up Next sync, if we don't have this episode it's most likely local only on some other device
                        // handle this here by adding it to our Up Next
                        newEpisode.podcastUuid = DataConstants.userEpisodeFakePodcastId
                        newEpisode.title = episodeInfo.title
                        DataManager.sharedManager.save(playlistEpisode: newEpisode)
                    }
                    // 3. The episode is not in the local database, and is not custom so it will attempt to retrieve the episode from
                    // the server. And will only add the episode if that succeeds.
                    else {
                        FileLog.shared.addMessage("UpNextSyncTask: Episode \(episodeInfo.title) is not in the local DB, fetching from the server...")

                        // we don't have this episode locally, so try and find it and add it to our database
                        // if we can't find it, don't add it to Up Next, since we can't support episodes that don't have parent podcasts
                        let upNextItem = UpNextItem(podcastUuid: episodeInfo.podcast, episodeUuid: episodeInfo.uuid, title: episodeInfo.title, url: episodeInfo.url, published: episodeInfo.published.date)
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        ServerPodcastManager.shared.addPodcastFromUpNextItem(upNextItem) { added in
                            if added {
                                FileLog.shared.addMessage("UpNextSyncTask [EpisodeServerFetch]: Episode (UUID: \(episodeInfo.uuid) - Title: \(episodeInfo.title)) found! Adding to the queue.")

                                newEpisode.podcastUuid = episodeInfo.podcast
                                newEpisode.title = episodeInfo.title
                                DataManager.sharedManager.save(playlistEpisode: newEpisode)
                            } else {
                                FileLog.shared.addMessage("UpNextSyncTask [EpisodeServerFetch]: Episode (UUID: \(episodeInfo.uuid) - Title: \(episodeInfo.title)) NOT FOUND. It will not be added to the queue")
                            }

                            dispatchGroup.leave()
                        }
                        _ = dispatchGroup.wait(timeout: .now() + 15.seconds)
                    }
                }
            }
        }

        FileLog.shared.addMessage("UpNextSyncTask: All done adding remote episodes to the queue")

        // Add any episodes from the local queue that were not included in the server's queue to
        // "keep" list to make sure they are not removed.
        //
        // 🚨 THIS IS A NON-DESTRUCTIVE MERGE 🚨
        // Meaning any episodes that exist on the server and locally will be kept regardless of if they were removed from
        // the another device or not.
        //
        // This can result in episodes being "added back" after logging in on a different device,
        // however this is preferable to accidentally deleting data.
        //
        var didMerge = false

        if reason == .login {
            // Get all the locally added episodes, and add them to the uuids list to make sure they aren't
            // removed unintentionally.
            let localUUIDs = localEpisodes.compactMap { uuids.contains($0.uuid) ? nil : $0.uuid }

            if localUUIDs.count != 0 {
                FileLog.shared.addMessage("UpNextSyncTask: Merging \(localEpisodes.count) local episodes that were not in the remote server call")

                uuids.append(contentsOf: localUUIDs)
                didMerge = true
            }
        }

        FileLog.shared.addMessage("UpNextSyncTask: The following \(uuids.count) episodes will be kept: \(uuids)")

        // Remove any episodes that no longer need to be in the queue.
        DataManager.sharedManager.deleteAllUpNextEpisodesNotIn(uuids: uuids)

        // Apply the new changes if needed.
        if didMerge {
            FileLog.shared.addMessage("UpNextSyncTask: Local and remote episode merge detected, saving updated queue to the server.")

            // Now that we've finalized the merge between the remote and local changes. This will now be considered
            // the source of truth, so persist the local queue and send it to the server to be saved
            ServerConfig.shared.playbackDelegate?.queuePersistLocalCopyAsReplace()
        }

        ServerConfig.shared.playbackDelegate?.queueRefreshList(checkForAutoDownload: true)

        ServerConfig.shared.playbackDelegate?.upNextQueueChanged()
        if let episodePlayingBeforeChanges = episodePlayingBeforeChanges, let currentlyPlaying = ServerConfig.shared.playbackDelegate?.isNowPlayingEpisode(episodeUuid: episodePlayingBeforeChanges.uuid), currentlyPlaying == false {
            // currently playing episode has changed
            ServerConfig.shared.playbackDelegate?.playingEpisodeChangedExternally()
        } else if episodePlayingBeforeChanges == nil, modifiedList.count > 0 {
            // nothing was playing but now it is
            ServerConfig.shared.playbackDelegate?.playingEpisodeChangedExternally()
        } else if episodePlayingBeforeChanges != nil, modifiedList.count == 0 {
            // there was something playing but it should no longer be playing
            ServerConfig.shared.playbackDelegate?.playingEpisodeChangedExternally()
        }
    }

    private func addPlayingEpisode(list: [Api_UpNextResponse.EpisodeResponse]) -> [Api_UpNextResponse.EpisodeResponse] {
        guard let isPlaying = ServerConfig.shared.playbackDelegate?.playing(), isPlaying == true else { return list }

        guard let playingEpisode = ServerConfig.shared.playbackDelegate?.currentEpisode() else { return list }

        // check it isn't already the top episode
        if let firstEpisode = list.first, firstEpisode.uuid == playingEpisode.uuid { return list }

        // move it to the top
        var modifiedList = list
        for (index, episode) in modifiedList.enumerated() {
            if episode.uuid == playingEpisode.uuid {
                modifiedList.remove(at: index)
                break
            }
        }

        var episodeInfo = Api_UpNextResponse.EpisodeResponse()
        episodeInfo.uuid = playingEpisode.uuid
        episodeInfo.title = playingEpisode.displayableTitle()
        episodeInfo.url = playingEpisode.downloadUrl ?? ""
        episodeInfo.podcast = playingEpisode.parentIdentifier()
        modifiedList.insert(episodeInfo, at: 0)

        return modifiedList
    }

    private func clearSyncedData(latestActionTime: Int64) {
        DataManager.sharedManager.deleteChangesOlderThan(utcTime: latestActionTime)
    }

    private func convertToProto(action: UpNextChanges) -> Api_UpNextChanges.Change? {
        // a replace involves multiple episodes and a slightly different format, so handle that seperately
        if action.type == UpNextChanges.Actions.replace.rawValue {
            guard let uuids = action.uuids else { return nil }

            var change = Api_UpNextChanges.Change()
            change.action = action.type
            change.modified = action.utcTime
            let uuidArr = uuids.components(separatedBy: ",")
            var episodes = [Api_UpNextEpisodeRequest]()
            for uuid in uuidArr {
                if let episode = DataManager.sharedManager.findBaseEpisode(uuid: uuid) {
                    var episodeInfo = Api_UpNextEpisodeRequest()
                    episodeInfo.title = episode.displayableTitle()
                    episodeInfo.url = episode.downloadUrl ?? ""
                    episodeInfo.podcast = episode.parentIdentifier()
                    episodeInfo.uuid = episode.uuid
                    if let date = episode.publishedDate {
                        episodeInfo.published = Google_Protobuf_Timestamp(date: date)
                    }

                    episodes.append(episodeInfo)
                }
            }
            change.episodes = episodes

            return change
        }

        guard let uuid = action.uuid else { return nil }

        // otherwise if it's not a replace just send the single episode
        var change = Api_UpNextChanges.Change()
        change.uuid = uuid
        change.action = action.type
        change.modified = action.utcTime

        if let episode = DataManager.sharedManager.findBaseEpisode(uuid: uuid) {
            change.title = episode.displayableTitle()
            if episode is Episode, let url = episode.downloadUrl {
                change.url = url
            }
            change.podcast = episode.parentIdentifier()
            if let date = episode.publishedDate {
                change.published = Google_Protobuf_Timestamp(date: date)
            }
        }

        return change
    }

    private func upNextServerModified() -> Int64? {
        if let modifiedStr = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.upNextServerLastModified), modifiedStr.count > 0 {
            return Int64(modifiedStr)
        }

        return nil
    }
}
