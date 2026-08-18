import Combine
import Foundation
import PocketCastsDataModel

@MainActor
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
        .receive(on: RunLoop.main)
        .map { [unowned self] _ in
            MainActor.assumeIsolated { self.playSource.allPodcastsInFolder(folder: folder) }
        }
        .assign(to: &$podcasts)
    }
}
