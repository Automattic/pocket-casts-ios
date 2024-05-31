import PocketCastsDataModel
import PocketCastsServer

class FolderHistoryModel: ObservableObject {
    @Published var historyEntries: [FolderHistoryManager.PodcastFoldersHistoryEntry] = []
    @Published var podcastsAndFolders: [(Podcast, Folder)] = []

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

    @MainActor
    func loadFoldersHistory(for entry: Date) {
        Task {
            podcastsAndFolders = dataManager.folderHistory(entry: entry).compactMap {
                if let podcast = dataManager.findPodcast(uuid: $0.key),
                   let folder = dataManager.findFolder(uuid: $0.value) {
                    return (podcast, folder)
                }

                return nil
            }
        }
    }

    func restore() {
        podcastsAndFolders.forEach { podcast, folder in
            podcast.folderUuid = folder.uuid
            podcast.syncStatus = SyncStatus.notSynced.rawValue
            dataManager.save(podcast: podcast)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)
        }
        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        Toast.show(L10n.restoreFoldersSuccess)
    }
}
