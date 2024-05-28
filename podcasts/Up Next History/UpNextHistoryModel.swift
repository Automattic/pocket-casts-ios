import PocketCastsDataModel
import PocketCastsServer

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [UpNextHistoryManager.UpNextHistoryEntry] = []

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

    func replaceUpNext(entry: Date) {
        Task {
            PlaybackManager.shared.endPlayback()
            dataManager.replaceUpNext(entry: entry)
            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)
        }
    }

    func reAddMissingItems(entry: Date) {
        Task {
            let episodesUuid = dataManager.upNextHistoryEpisodes(entry: entry)
            episodesUuid.forEach { episodeUuid in
                if let episode = dataManager.findEpisode(uuid: episodeUuid) {
                    PlaybackManager.shared.addToUpNext(episode: episode, userInitiated: false)
                }
            }
            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)
        }
    }
}
