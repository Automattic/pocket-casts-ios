import DataModel
import Foundation
import SwiftProtobuf
import Utils

class UpNextSyncTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        var syncRequest = Api_UpNextSyncRequest()
        syncRequest.deviceTime = TimeFormatter.currentUTCTimeInMillis()
        syncRequest.version = apiVersion
        var upNextChanges = Api_UpNextChanges()
        var latestActionTime: Int64 = 0
        var changes = [Api_UpNextChanges.Change]()
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

        FileLog.shared.addMessage("UpNextSyncTask: Syncing Up Next, sending \(changes.count) changes, modified time \(upNextChanges.serverModified)")
        let url = Server.Urls.api + "up_next/sync"
        do {
            let data = try syncRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)
            if httpStatus == Server.HttpConstants.notModified {
                // no changes that we need to process
                FileLog.shared.addMessage("UpNextSyncTask: Server returned not modified to Up Next sync, no changes required")
            } else if let response = response, httpStatus == Server.HttpConstants.ok {
                process(serverData: response, latestActionTime: latestActionTime)
            } else {
                FileLog.shared.addMessage("UpNextSyncTask:  Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("UpNextSyncTask:  had issues encoding protobuf \(error.localizedDescription)")
        }
    }

    private func process(serverData: Data, latestActionTime: Int64) {
        do {
            let response = try Api_UpNextResponse(serializedData: serverData)
            applyServerChanges(episodes: response.episodes)

            // save the server last modified so we can send it back next time. For legacy compatibility this is stored as a string
            UserDefaults.standard.set("\(response.serverModified)", forKey: Constants.UserDefaults.upNextServerLastModified)

            clearSyncedData(latestActionTime: latestActionTime)
        } catch {
            FileLog.shared.addMessage("UpNextSyncTask: Failed to decode server data")
        }
    }

    private func applyServerChanges(episodes: [Api_UpNextResponse.EpisodeResponse]) {
        if upNextServerModified() == nil, episodes.count == 0, PlaybackManager.shared.currentEpisode() != nil {
            // if this is our first sync (eg: no server modified stored) and the server sent us a blank list, set our Up Next to be the actual list so that it doesn't get cleared
            PlaybackManager.shared.queue.persistLocalCopyAsReplace()
            FileLog.shared.addMessage("UpNextSyncTask: Got back an empty up next to what looks like our first ever Up Next sync, saving local copy as a replace")

            return
        }

        // check that the server list doesn't exactly match our list, if it does, no need to do anything
        let localEpisodes = PlaybackManager.shared.queue.allEpisodes()
        if localEpisodes.count == episodes.count {
            // if they are both 0, nothing to do
            if localEpisodes.count == 0 {
                FileLog.shared.addMessage("UpNextSyncTask: no local or remote episodes, nothing action required")
                return
            }

            var allMatch = true
            for (index, episode) in episodes.enumerated() {
                if episode.uuid != localEpisodes[index].uuid {
                    allMatch = false
                }
            }
            if allMatch {
                FileLog.shared.addMessage("UpNextSyncTask: server copy matches our copy, nothing action required")
                return
            }
        }

        let modifiedList = addPlayingEpisode(list: episodes)
        FileLog.shared.addMessage("UpNextSyncTask: server sent \(episodes.count) episodes, we have \(modifiedList.count), making changes")

        let episodePlayingBeforeChanges = PlaybackManager.shared.currentEpisode()
        var uuids = [String]()
        if modifiedList.count > 0 {
            for (index, episodeInfo) in modifiedList.enumerated() {
                uuids.append(episodeInfo.uuid)
                if let existingEpisode = DataManager.sharedManager.findPlaylistEpisode(uuid: episodeInfo.uuid) {
                    if existingEpisode.episodePosition != Int32(index) {
                        existingEpisode.episodePosition = Int32(index)
                        DataManager.sharedManager.save(playlistEpisode: existingEpisode)
                    }
                } else {
                    let newEpisode = PlaylistEpisode()
                    newEpisode.episodePosition = Int32(index)
                    newEpisode.episodeUuid = episodeInfo.uuid
                    if let localEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeInfo.uuid) {
                        // we already have this episode, so all good save the Up Next item
                        newEpisode.podcastUuid = localEpisode.parentIdentifier()
                        newEpisode.title = localEpisode.optimisedTitle()
                        DataManager.sharedManager.save(playlistEpisode: newEpisode)
                    } else if episodeInfo.podcast == Constants.Values.userEpisodeFakePodcastId {
                        // because a custom episode import task always runs before an Up Next sync, if we don't have this episode it's most likely local only on some other device
                        // handle this here by adding it to our Up Next
                        newEpisode.podcastUuid = Constants.Values.userEpisodeFakePodcastId
                        newEpisode.title = episodeInfo.title
                        DataManager.sharedManager.save(playlistEpisode: newEpisode)
                    } else {
                        // we don't have this episode locally, so try and find it and add it to our database
                        // if we can't find it, don't add it to Up Next, since we can't support episodes that don't have parent podcasts
                        let upNextItem = UpNextItem(podcastUuid: episodeInfo.podcast, episodeUuid: episodeInfo.uuid, title: episodeInfo.title, url: episodeInfo.url, published: episodeInfo.published.date)
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        PodcastManager.shared.addPodcastFromUpNextItem(upNextItem) { added in
                            if added {
                                newEpisode.podcastUuid = episodeInfo.podcast
                                newEpisode.title = episodeInfo.title
                                DataManager.sharedManager.save(playlistEpisode: newEpisode)
                            }

                            dispatchGroup.leave()
                        }
                        _ = dispatchGroup.wait(timeout: .now() + 15.seconds)
                    }
                }
            }
        }

        DataManager.sharedManager.deleteAllUpNextEpisodesNotIn(uuids: uuids)
        PlaybackManager.shared.queue.refreshList(checkForAutoDownload: true)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.upNextQueueChanged)

        if let episodePlayingBeforeChanges = episodePlayingBeforeChanges, !PlaybackManager.shared.currentlyPlaying(episode: episodePlayingBeforeChanges) {
            // currently playing episode has changed
            PlaybackManager.shared.playingEpisodeDidChange()
        } else if episodePlayingBeforeChanges == nil, modifiedList.count > 0 {
            // nothing was playing but now it is
            PlaybackManager.shared.playingEpisodeDidChange()
        } else if episodePlayingBeforeChanges != nil, modifiedList.count == 0 {
            // there was something playing but it should no longer be playing
            PlaybackManager.shared.playingEpisodeDidChange()
        }
    }

    private func addPlayingEpisode(list: [Api_UpNextResponse.EpisodeResponse]) -> [Api_UpNextResponse.EpisodeResponse] {
        if !PlaybackManager.shared.playing() { return list }

        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return list }

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
        episodeInfo.title = playingEpisode.optimisedTitle()
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
                    episodeInfo.title = episode.optimisedTitle()
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
            change.title = episode.optimisedTitle()
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
        if let modifiedStr = UserDefaults.standard.string(forKey: Constants.UserDefaults.upNextServerLastModified), modifiedStr.count > 0 {
            return Int64(modifiedStr)
        }

        return nil
    }
}
