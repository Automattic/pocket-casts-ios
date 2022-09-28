import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class SyncHistoryTask: ApiBaseTask {
    enum HistoryAction: Int {
        case add = 1, delete = 2, clearAll = 3
    }

    override func apiTokenAcquired(token: String) {
        var dataToSync = Api_HistorySyncRequest()
        dataToSync.deviceTime = TimeFormatter.currentUTCTimeInMillis()
        dataToSync.version = apiVersion

        // find changes if there are any
        var changes = [Api_HistoryChange]()
        let episodesThatNeedSyncing = DataManager.sharedManager.findEpisodesWhere(customWhere: "lastPlaybackInteractionSyncStatus <> \(SyncStatus.synced.rawValue) AND lastPlaybackInteractionDate IS NOT NULL ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000", arguments: nil)
        if episodesThatNeedSyncing.count > 0 {
            for episode in episodesThatNeedSyncing {
                if let episodeProto = convertToProto(episode: episode) {
                    changes.append(episodeProto)
                }
            }
        }

        if let clearDate = ServerSettings.lastClearHistoryDate() {
            var clearAllChange = Api_HistoryChange()
            clearAllChange.action = Int32(HistoryAction.clearAll.rawValue)
            clearAllChange.modifiedAt = Int64(clearDate.timeIntervalSince1970 * 1000)
            changes.append(clearAllChange)
        }

        dataToSync.changes = changes
        if let serverModified = historyServerModified() {
            dataToSync.serverModified = serverModified
        }

        let url = ServerConstants.Urls.api() + "history/sync"
        do {
            let data = try dataToSync.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)
            if httpStatus == ServerConstants.HttpConstants.notModified {
                DataManager.sharedManager.markAllEpisodePlaybackHistorySynced()
            } else if let response = response, httpStatus == ServerConstants.HttpConstants.ok {
                process(serverData: response)
            } else {
                print("SyncHistoryTask Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            print("SyncHistoryTask had issues encoding protobuf \(error.localizedDescription)")
        }
    }

    private func process(serverData: Data) {
        do {
            let response = try Api_HistoryResponse(serializedData: serverData)

            // on watchOS, we don't show history, so we also don't process server changes we only want to push changes up, not down
            #if !os(watchOS)
                updateEpisodes(updates: response.changes)
            #endif

            // save the server last modified so we can send it back next time
            UserDefaults.standard.set("\(response.serverModified)", forKey: ServerConstants.UserDefaults.historyServerLastModified)

            let lastCleared = response.lastCleared
            if lastCleared > 0 {
                let clearedDate = Date(timeIntervalSince1970: TimeInterval(lastCleared / 1000))
                DataManager.sharedManager.clearEpisodePlaybackInteractionDatesBefore(date: clearedDate)
                ServerSettings.setLastClearHistoryDate(nil)
            }
            DataManager.sharedManager.markAllEpisodePlaybackHistorySynced()
        } catch {
            print("SyncHistoryTask had issues decoding protobuf \(error.localizedDescription)")
        }
    }

    private func updateEpisodes(updates: [Api_HistoryChange]) {
        for (index, change) in updates.enumerated() {
            // there can be up to 1000 episodes returned from this call, for performance reasons, only grab up to the limit
            if index > ServerConstants.Limits.maxHistoryItems { return }

            if change.action == HistoryAction.add.rawValue {
                let interactionDate = Date(timeIntervalSince1970: TimeInterval(change.modifiedAt / 1000))
                if let episode = DataManager.sharedManager.findEpisode(uuid: change.episode) {
                    if episode.lastPlaybackInteractionDate == nil || interactionDate > episode.lastPlaybackInteractionDate! {
                        DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: episode.uuid)
                    }
                } else {
                    ServerPodcastManager.shared.addMissingPodcast(episodeUuid: change.episode, podcastUuid: change.podcast)
                    DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: change.episode)
                }
            } else if change.action == HistoryAction.delete.rawValue {
                DataManager.sharedManager.clearEpisodePlaybackInteractionDate(episodeUuid: change.episode)
            }
        }
    }

    private func convertToProto(episode: Episode) -> Api_HistoryChange? {
        guard let playbackDate = episode.lastPlaybackInteractionDate else { return nil }

        // there was a crash where the playbackDate was bigger than Int64 could hold, which means something went wrong somewhere, but here we ignore that value and don't sync it
        let modifiedAt = playbackDate.timeIntervalSince1970 * 1000.0
        if modifiedAt > Double(Int64.max) { return nil }

        var change = Api_HistoryChange()
        change.action = episode.lastPlaybackInteractionSyncStatus == SyncStatus.notSyncedRemove.rawValue ? 2 : 1
        change.episode = episode.uuid
        change.podcast = episode.podcastUuid
        change.modifiedAt = Int64(modifiedAt)
        change.title = episode.displayableTitle()
        change.url = episode.downloadUrl ?? ""
        if let publishedDate = episode.publishedDate {
            change.published = Google_Protobuf_Timestamp(date: publishedDate)
        }

        return change
    }

    private func historyServerModified() -> Int64? {
        if let modifiedStr = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.historyServerLastModified), modifiedStr.count > 0 {
            return Int64(modifiedStr)
        }

        return nil
    }
}
