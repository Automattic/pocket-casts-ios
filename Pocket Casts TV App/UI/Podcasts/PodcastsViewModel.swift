import SwiftUI
import Combine

@Observable
class PodcastsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [MockPodcast] = []
    var folders: [MockFolder] = []

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                podcasts = MockData.makePodcasts()
                folders = MockData.makeFolders()
                state = podcasts.isEmpty ? .empty : .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
