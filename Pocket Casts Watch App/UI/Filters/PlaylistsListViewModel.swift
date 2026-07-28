import Combine
import Foundation
import PocketCastsDataModel

class PlaylistsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var playlists: [PlaylistRepresentable] = []
    private let playSourceViewModel = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.Notification.dataUpdated
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] _ in
                self.loadData()
            })
            .store(in: &cancellables)
    }

    public func loadData() {
        isLoading = true
        playSourceViewModel.fetchPlaylists()
            .replaceError(with: [])
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] playlists in
                self.isLoading = false
                self.playlists = playlists
            })
            .store(in: &cancellables)
    }

    func episodeCount(for playlist: PlaylistRepresentable) -> Int {
        return playSourceViewModel.episodeCount(for: playlist)
    }
}
