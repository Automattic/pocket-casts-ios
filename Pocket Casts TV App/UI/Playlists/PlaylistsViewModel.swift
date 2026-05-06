import SwiftUI
import Combine

@Observable
class PlaylistsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var playlists: [MockPlaylist] = []

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .ready
                playlists = MockData.makePlaylists()
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
