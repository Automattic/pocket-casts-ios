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
    var playlists: [EpisodeFilter] = []

    func load() {
        Task { [weak self] in
            guard let self else { return }
            let playlists = dataManager.allPlaylists(includeDeleted: false)
            await MainActor.run {
                self.playlists = playlists
                self.state = playlists.isEmpty ? .empty : .ready
            }
        }
    }

    private func observePlaylistChanges() {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: Constants.Notifications.playlistChanged),
            NotificationCenter.default.publisher(for: ServerNotifications.syncCompleted)
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.load()
        }
        .store(in: &cancellables)
    }
}
