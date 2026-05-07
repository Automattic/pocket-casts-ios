import SwiftUI
import Combine
import PocketCastsServer
import PocketCastsUtils
import PocketCastsDataModel

enum PodcastViewModelState: Equatable, Hashable {
    case loading
    case ready
    case empty
}

protocol PodcastsViewModelInterface: AnyObject, Observation.Observable {

    var state: PodcastViewModelState { get }

    var podcasts: [Podcast] { get }

    func load() async
}

@Observable
class PodcastsViewModel: PodcastsViewModelInterface {
    private var cancellables: Set<AnyCancellable> = []

    private(set) var state: PodcastViewModelState = .loading

    var podcasts: [Podcast] = []

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    func load() async {
        await fetchPodcasts()
    }

    private func fetchPodcasts() async {
        Task {
            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false)
            await MainActor.run {
                self.podcasts = podcasts
                self.state = .ready
            }
        }
    }
}

@Observable
class PodcastsViewModelMock: PodcastsViewModelInterface {

    private var cancellable: AnyCancellable?

    var state: PodcastViewModelState = .loading

    var podcasts: [Podcast] = []

    func load() async {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                podcasts = MockData.makeStubPodcasts()
                state = podcasts.isEmpty ? .empty : .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
