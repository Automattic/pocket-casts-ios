import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

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

    private(set) var sortOrder: LibrarySort

    @ObservationIgnored private var fetchTask: Task<Void, Never>?

    init(folder: Folder, dataManager: DataManager = DataManager.shared) {
        self.folder = folder
        self.dataManager = dataManager
        self.sortOrder = Self.sortOrder(for: folder)
    }

    /// `folder.sortType` is stored using the old `LibrarySort.Old` raw-value scheme (1/2/5/6/7).
    private static func sortOrder(for folder: Folder) -> LibrarySort {
        LibrarySort(oldValue: Int(folder.sortType)) ?? .dateAddedNewestToOldest
    }

    func load() {
        reloadPodcasts { [weak self] podcasts in
            guard let self else { return }
            Analytics.track(.folderShown, properties: [
                "number_of_podcasts": podcasts.count,
                "sort_order": self.sortOrder
            ])
        }
    }

    /// Persists the sort order on the folder (synced, same as the iOS app), then reloads the podcasts.
    func setSortOrder(_ order: LibrarySort) {
        guard order != sortOrder else { return }
        folder.sortType = Int32(order.old.rawValue)
        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        dataManager.save(folder: folder)
        sortOrder = order
        Analytics.track(.folderSortByChanged, properties: ["sort_order": order])
        reloadPodcasts()
    }

    /// Cancels any reload still in flight, so a slower fetch for an older sort order
    /// can't finish last and overwrite the newer results.
    private func reloadPodcasts(completion: (([Podcast]) -> Void)? = nil) {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }
            let podcasts = self.dataManager.allPodcastsInFolder(folder: self.folder)
            await MainActor.run {
                // Cancellation happens on the main thread, so this check can't miss a newer reload.
                guard !Task.isCancelled else { return }
                self.podcasts = podcasts
                self.state = podcasts.isEmpty ? .empty : .ready
                completion?(podcasts)
            }
        }
    }
}
