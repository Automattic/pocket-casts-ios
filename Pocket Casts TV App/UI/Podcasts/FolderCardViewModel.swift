import PocketCastsDataModel

@Observable
class FolderCardViewModel {

    var folder: Folder
    let dataManager: DataManager

    var topPodcastsUuids: [String] = []

    init(folder: Folder, dataManager: DataManager = DataManager.sharedManager) {
        self.folder = folder
        self.dataManager = dataManager
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            let podcastUuids = dataManager.topPodcastsUuidInFolder(folder: folder)
            await MainActor.run {
                self.topPodcastsUuids = podcastUuids
            }
        }
    }
}
