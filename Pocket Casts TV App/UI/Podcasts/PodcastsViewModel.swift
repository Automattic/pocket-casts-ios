import SwiftUI

@Observable
class PodcastsViewModel {

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [MockPodcast] = []
    var folders: [MockFolder] = []

    func load() async {
        try? await Task.sleep(for: .seconds(1))
        podcasts = MockData.makePodcasts()
        folders = MockData.makeFolders()
        state = podcasts.isEmpty ? .empty : .ready
    }
}
