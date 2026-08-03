import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@Observable
class PlaylistsViewModel {

    private var cancellables: Set<AnyCancellable> = []

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
        observePlaylistChanges()
    }
    var playlists: [PlaylistItem] = []

    func load() async {
        if state == .loading {
            RefreshManager.shared.refreshPodcasts()
        }
        let originalPlaylists = dataManager.allPlaylists(includeDeleted: false)
        let playlists = originalPlaylists.sorted { a, b in
            switch (a.isDownloadFilterActive, b.isDownloadFilterActive) {
            case (true, true), (false, false):
                return a.sortPosition < b.sortPosition
            case (true, false):
                return false
            case (false, true):
                return true
            }
        }
        await MainActor.run {
            self.playlists = playlists.map({ playlist in
                PlaylistItem(playlist: playlist)
            })
            self.state = playlists.isEmpty ? .empty : .ready
        }
    }

    private func observePlaylistChanges() {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: Constants.Notifications.playlistChanged),
            NotificationCenter.default.publisher(for: ServerNotifications.syncCompleted)
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            Task {
                await self?.load()
            }
        }
        .store(in: &cancellables)
    }
}

extension EpisodeFilter {

    var isDownloadFilterActive: Bool {
        return !(filterDownloaded && filterDownloading && filterNotDownloaded) && (filterDownloaded)
    }
}
