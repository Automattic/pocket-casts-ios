import Combine
import Foundation
import PocketCastsDataModel

class FolderViewModel: ObservableObject {
    @Published var folder: Folder
    @Published var podcasts = [Podcast]()

    private let playSource = WatchSourceViewModel()
    private var cancellables = Set<AnyCancellable>()

    init(folder: Folder) {
        self.folder = folder
        podcasts = playSource.allPodcastsInFolder(folder: folder)

        Publishers.Merge(
            Publishers.Notification.dataUpdated,
            Publishers.Notification.folderChanged
        )
        .map { [unowned self] _ in
            self.playSource.allPodcastsInFolder(folder: folder)
        }
        .receive(on: RunLoop.main)
        .assign(to: &$podcasts)
    }
}
