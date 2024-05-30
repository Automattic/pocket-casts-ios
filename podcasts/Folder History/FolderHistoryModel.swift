import PocketCastsDataModel
import PocketCastsServer

class FolderHistoryModel: ObservableObject {
    @Published var historyEntries: [FolderHistoryManager.PodcastFoldersHistoryEntry] = []

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = dataManager.foldersHistoryEntries()
        }
    }
}
