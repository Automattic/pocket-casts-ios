import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [UpNextHistoryManager.UpNextHistoryEntry] = []
    @Published var episodes: [BaseEpisode] = []

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = dataManager.upNextHistoryEntries()
        }
    }

    @MainActor
    func loadEpisodes(for entry: Date) {
        Task {
            let episodesUuid = dataManager.upNextHistoryEpisodes(entry: entry)
            episodes = episodesUuid.compactMap { dataManager.findBaseEpisode(uuid: $0) }
        }
    }

    func reAddMissingItems(entry: Date) {
        Task {
            let episodesUuid = dataManager.upNextHistoryEpisodes(entry: entry)
            FileLog.shared.addMessage("UpNextHistory: Restoring entries from \(entry) with episodes: [\(episodesUuid.joined(separator: ","))]")
            episodesUuid.forEach { episodeUuid in
                if let episode = dataManager.findBaseEpisode(uuid: episodeUuid) {
                    PlaybackManager.shared.addToUpNext(episode: episode, ignoringQueueLimit: true, userInitiated: false)
                }
            }
            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)

            let upNextQueueCount = PlaybackManager.shared.upNextQueueCount()
            FileLog.shared.addMessage("UpNextHistory: Restored Up Next Queue to \(upNextQueueCount) episodes")
        }
    }
}
