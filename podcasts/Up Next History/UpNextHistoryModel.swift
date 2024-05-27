import PocketCastsDataModel

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [UpNextHistoryManager.UpNextHistoryEntry] = []

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = DataManager.sharedManager.upNextHistoryEntries()
        }
    }
}
