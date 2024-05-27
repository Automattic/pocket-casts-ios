import PocketCastsDataModel

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [Date] = []

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = DataManager.sharedManager.upNextHistoryEntries()
        }
    }
}
