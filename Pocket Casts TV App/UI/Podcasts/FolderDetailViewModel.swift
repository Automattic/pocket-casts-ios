import Combine
import Foundation
import PocketCastsDataModel

@Observable
class FolderDetailViewModel {

    var folder: Folder
    var podcasts = [Podcast]()
    private var dataManager: DataManager

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    init(folder: Folder, dataManager: DataManager = DataManager.sharedManager) {
        self.folder = folder
        self.dataManager = dataManager
    }

    func load() {
        Task {
            let podcasts = dataManager.allPodcastsInFolder(folder: folder)
            await MainActor.run {
                self.podcasts = podcasts
                self.state = podcasts.isEmpty ? .empty : .ready
                Analytics.track(.folderShown, properties: [
                    "number_of_podcasts": podcasts.count,
                    "sort_order": Self.sortOrderAnalyticsValue(for: folder)
                ])
            }
        }
    }

    /// Mirrors iOS `Folder.librarySort().analyticsDescription`. `folder.sortType` is stored
    /// using the old `LibrarySort.Old` raw-value scheme (1/2/5/6/7), not `LibrarySort`'s native values.
    private static func sortOrderAnalyticsValue(for folder: Folder) -> String {
        switch Int(folder.sortType) {
        case 1: return "date_added"
        case 2: return "name"
        case 5: return "episode_release_date"
        case 6: return "drag_and_drop"
        case 7: return "episode_recently_played"
        default: return "date_added"
        }
    }
}
