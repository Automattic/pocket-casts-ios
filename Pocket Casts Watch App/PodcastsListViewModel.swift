import Combine
import Foundation
import PocketCastsDataModel
import SwiftUI

class PodcastsListViewModel: ObservableObject {
    @Published var gridItems = [HomeGridItem]()
    @Published var sortOrder: LibrarySort {
        willSet {
            playSource.podcastSortOrder = newValue
        }
    }

    private let playSource = WatchSourceViewModel()

    init() {
        sortOrder = playSource.podcastSortOrder

        Publishers.Merge(
            Publishers.Notification.dataUpdated.map { [unowned self] _ in sortOrder },
            $sortOrder
        ).map { [unowned self] sortingOption in
            self.playSource.allHomeGridItemsSorted(sortedBy: sortingOption)
        }
        .receive(on: RunLoop.main)
        .assign(to: &$gridItems)
    }

    func countOfPodcastsInFolder(_ folder: Folder) -> Int {
        DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
    }
}
