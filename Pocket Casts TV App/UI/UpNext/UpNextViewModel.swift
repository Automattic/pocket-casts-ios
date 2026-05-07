import SwiftUI
import Combine

@Observable
class UpNextViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var episodes: [MockEpisode] = []

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                episodes = MockData.makeUpNext()
                state = episodes.isEmpty ? .empty : .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
