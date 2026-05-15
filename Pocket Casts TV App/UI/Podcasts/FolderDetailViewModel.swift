import Combine
import Foundation
import PocketCastsDataModel

@Observable
class FolderDetailViewModel {

    var folder: Folder
    var podcasts = [Podcast]()
    private var dataManager: DataManager

    private var cancellables = Set<AnyCancellable>()

    init(folder: Folder, dataManager: DataManager = DataManager.sharedManager) {
        self.folder = folder
        self.dataManager = dataManager
    }

    func load() {
        Task {
            let podcasts = dataManager.allPodcastsInFolder(folder: folder)
            await MainActor.run {
                self.podcasts = podcasts
            }
        }
    }
}
