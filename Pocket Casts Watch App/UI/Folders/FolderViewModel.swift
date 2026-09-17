import Combine
import Foundation
import PocketCastsDataModel

@MainActor
class FolderViewModel: ObservableObject {
    @Published var folder: Folder
    @Published var podcasts = [Podcast]()

    private let playSource = WatchSourceViewModel()

    init(folder: Folder) {
        self.folder = folder
        podcasts = playSource.allPodcastsInFolder(folder: folder)

        Publishers.Merge(
            Publishers.Notification.dataUpdated,
            Publishers.Notification.folderChanged
        )
        .receive(on: RunLoop.main)
        .map { [unowned self] _ in
            self.playSource.allPodcastsInFolder(folder: folder)
        }
        .assign(to: &$podcasts)
    }
}
