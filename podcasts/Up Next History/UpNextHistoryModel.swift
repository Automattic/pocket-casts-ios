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
}
