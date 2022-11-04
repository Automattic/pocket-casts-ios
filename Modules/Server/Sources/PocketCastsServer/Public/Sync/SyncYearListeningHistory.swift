import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class SyncYearListeningHistory: ApiBaseTask {
    private var token: String?

    override func apiTokenAcquired(token: String) {
        self.token = token

        performRequest(token: token, shouldSync: false)
    }

    private func performRequest(token: String, shouldSync: Bool) {
        var dataToSync = Api_YearHistoryRequest()
        dataToSync.deviceTime = TimeFormatter.currentUTCTimeInMillis()
        dataToSync.version = apiVersion
        dataToSync.year = 2022
        dataToSync.count = !shouldSync

        let url = ServerConstants.Urls.api() + "history/year"
        do {
            let data = try dataToSync.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)
            if let response = response, httpStatus == ServerConstants.HttpConstants.ok {
                if !shouldSync {
                    compareNumberOfEpisodes(serverData: response)
                } else {
                    syncMissingEpisodes(serverData: response)
                }
            } else {
                print("SyncYearListeningHistory Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            print("SyncYearListeningHistory had issues encoding protobuf \(error.localizedDescription)")
        }
    }

    private func compareNumberOfEpisodes(serverData: Data) {
        do {
            let response = try Api_YearHistoryResponse(serializedData: serverData)

            let localNumberOfEpisodes = DataManager.sharedManager.numberOfEpisodesThisYear()

            if response.count > localNumberOfEpisodes, let token {
                performRequest(token: token, shouldSync: true)
            }
        } catch {
            print("SyncYearListeningHistory had issues decoding protobuf \(error.localizedDescription)")
        }
    }

    private func syncMissingEpisodes(serverData: Data) {
        do {
            let response = try Api_YearHistoryResponse(serializedData: serverData)

            // on watchOS, we don't show history, so we also don't process server changes we only want to push changes up, not down
            #if !os(watchOS)
            updateEpisodes(updates: response.history.changes)
            #endif
        } catch {
            print("SyncYearListeningHistory had issues decoding protobuf \(error.localizedDescription)")
        }
    }

    private func updateEpisodes(updates: [Api_HistoryChange]) {
        for change in updates {
            let interactionDate = Date(timeIntervalSince1970: TimeInterval(change.modifiedAt / 1000))
            if DataManager.sharedManager.findEpisode(uuid: change.episode) == nil {
                // The episode is missing, add it

                // TODO: the server response is missing `playedUpTo`, we need that

                ServerPodcastManager.shared.addMissingPodcast(episodeUuid: change.episode, podcastUuid: change.podcast)
                _ = ServerPodcastManager.shared.addMissingEpisode(episodeUuid: change.episode, podcastUuid: change.podcast)
                DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: change.episode)
            }
        }
    }
}

public class SyncYearListeningHistoryWrapper {
    public static func start() {
        SyncYearListeningHistory().start()
    }
}
