import SwiftUI
import Combine
import PocketCastsDataModel

@Observable
class PlaylistsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
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
}
