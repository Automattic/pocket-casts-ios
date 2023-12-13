import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import Combine

public class SyncYearListeningProgress: ObservableObject {
    public static var shared = SyncYearListeningProgress()

    @Published public var progress: Double = 0

    var episodesToSync: Double = 0

    var syncedEpisodes: Double = 0

    @MainActor
    func episodeSynced() {
        syncedEpisodes += 1
        // There are a few additional requests after syncing episodes, so we hang on 95%
        progress = min(syncedEpisodes / episodesToSync, 0.95)
    }

    @MainActor
    public func reset() {
        progress = 0
        episodesToSync = 0
        syncedEpisodes = 0
    }
}

class SyncYearListeningHistoryTask: ApiBaseTask {
    private var token: String?

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
        dataToSync.version = apiVersion
        dataToSync.year = yearToSync
        dataToSync.count = !shouldSync

        let url = ServerConstants.Urls.api() + "history/year"
        do {
            let data = try dataToSync.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)
            if let response, httpStatus == ServerConstants.HttpConstants.ok {
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

            let localNumberOfEpisodes = DataManager.sharedManager.numberOfEpisodes(year: yearToSync)

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
        let lock = NSLock()

        var podcastsToUpdate: Set<String> = []

        // Get the list of missing episodes in the database
        let uuids = updates.map { $0.episode }
        let episodesThatExist = DataManager.sharedManager.episodesThatExist(year: yearToSync, uuids: uuids)
        let missingEpisodes = updates.filter { !episodesThatExist.contains($0.episode) }

        SyncYearListeningProgress.shared.episodesToSync += Double(missingEpisodes.count)

        let dispatchGroup = DispatchGroup()

        for change in missingEpisodes {
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                let interactionDate = Date(timeIntervalSince1970: TimeInterval(change.modifiedAt / 1000))

                ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: change.episode, podcastUuid: change.podcast)
                DataManager.sharedManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: change.episode)

                // Ensure podcastsToUpdate access is thread-safe to avoid crashes
                lock.lock()
                podcastsToUpdate.insert(change.podcast)
                lock.unlock()

                DispatchQueue.main.async {
                    SyncYearListeningProgress.shared.episodeSynced()
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        // Sync episode status for the retrieved podcasts' episodes
        updateEpisodes(for: podcastsToUpdate)
    }

    private func updateEpisodes(for podcastsUuids: Set<String>) {
        let dispatchGroup = DispatchGroup()

        podcastsUuids.forEach { podcastUuid in
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                if let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: podcastUuid) {
                    DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
    }
}

/// Helper that checks for podcast existence
/// It caches database requests
class PodcastExistsHelper {
    static let shared = PodcastExistsHelper()

    private var checkedUuidsThatExist: [String] = []

    private var lock = NSLock()

    func exists(uuid: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if checkedUuidsThatExist.contains(uuid) {
            return true
        }

        let exists = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) != nil

        if exists {
            checkedUuidsThatExist.append(uuid)
        }

        return exists
    }
}

public class YearListeningHistory {
    public static func sync() -> Bool {
        var syncResults: [Bool] = []
        let yearsToSync: [Int32] = SubscriptionHelper.hasActiveSubscription() ? [2023, 2022] : [2023]

        let dispatchGroup = DispatchGroup()
        yearsToSync.forEach { yearToSync in
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                let syncYearListeningHistory = SyncYearListeningHistoryTask.init(year: yearToSync)

                syncYearListeningHistory.start()

                syncResults.append(syncYearListeningHistory.success)

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        return syncResults.allSatisfy { $0 == true }
    }
}
