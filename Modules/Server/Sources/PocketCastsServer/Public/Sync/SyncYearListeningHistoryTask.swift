import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class SyncYearListeningHistoryTask: ApiBaseTask {
    private var token: String?

    private let podcastHelper = PodcastExistHelper()
    private let yearToSync: Int32

    var success: Bool = false

    init(year: Int32) {
        self.yearToSync = year
    }

    override func apiTokenAcquired(token: String) {
        self.token = token

        performRequest(token: token, shouldSync: false)
    }

    private func performRequest(token: String, shouldSync: Bool) {
        var dataToSync = Api_YearHistoryRequest()
        dataToSync.deviceTime = TimeFormatter.currentUTCTimeInMillis()
        dataToSync.version = apiVersion
        dataToSync.year = yearToSync
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
                print("SyncYearListeningHistory: \(Int(response.count) - localNumberOfEpisodes) episodes missing, adding them...")
                performRequest(token: token, shouldSync: true)
            } else {
                success = true
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

            success = true
        } catch {
            print("SyncYearListeningHistory had issues decoding protobuf \(error.localizedDescription)")
        }
    }

    private func updateEpisodes(updates: [Api_HistoryChange]) {
        var podcastsToUpdate: [String] = []

        let dispatchGroup = DispatchGroup()

        for change in updates {
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                let interactionDate = Date(timeIntervalSince1970: TimeInterval(change.modifiedAt / 1000))

                let episodeInDatabase = DataManager.sharedManager.findEpisode(uuid: change.episode)

                if episodeInDatabase == nil {
                    // Episode is not on database, let's add it

                    ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: change.episode, podcastUuid: change.podcast)
                    DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: change.episode)
                    podcastsToUpdate.append(change.podcast)
                } else if episodeInDatabase?.lastPlaybackInteractionDate == nil {
                    // Episode is in database but it's not updated, let's update it

                    DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: change.episode)
                    podcastsToUpdate.append(change.podcast)
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        // Sync episode status for the retrieved podcasts' episodes
        let uniqueUuidsToUpdate = Array(Set(podcastsToUpdate))
        updateEpisodes(for: uniqueUuidsToUpdate)
    }

    private func updateEpisodes(for podcastsUuids: [String]) {
        podcastsUuids.forEach {
            if let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: $0) {
                DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
            }
        }
    }
}

/// Helper that checks for podcast existence
/// It caches database requests
class PodcastExistHelper {
    static let shared = PodcastExistHelper()

    var checkedUuidsThatExist: [String] = []

    func exists(uuid: String) -> Bool {
        if checkedUuidsThatExist.contains(uuid) {
            return true
        }

        let exists = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) != nil

        if exists {
            checkedUuidsThatExist.append(uuid)
        }

        return exists
    }

    func markAsExistent(uuid: String) {
        checkedUuidsThatExist.append(uuid)
    }
}

public class YearListeningHistory {
    public static func sync() -> Bool {
        let syncYearListeningHistory = SyncYearListeningHistoryTask(year: 2022)

        syncYearListeningHistory.start()

        return syncYearListeningHistory.success
    }
}
