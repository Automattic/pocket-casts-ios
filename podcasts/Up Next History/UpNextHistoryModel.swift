import PocketCastsDataModel
import PocketCastsServer

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [UpNextHistoryManager.UpNextHistoryEntry] = []

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = DataManager.sharedManager.upNextHistoryEntries()
        }
    }

    func replaceUpNext(entry: Date) {
        Task {
            PlaybackManager.shared.endPlayback()
            DataManager.sharedManager.replaceUpNext(entry: entry)
            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)
        }
    }

    func reAddMissingItems(entry: Date) {
        Task {
            let episodesUuid = DataManager.sharedManager.upNextHistoryEpisodes(entry: entry)
            episodesUuid.forEach { episodeUuid in
                if let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) {
                    PlaybackManager.shared.addToUpNext(episode: episode, userInitiated: false)
                }
            }
            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)
        }
    }
}
