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

protocol PodcastsViewModelProtocol: AnyObject, Observation.Observable {

    var state: PodcastViewModelState { get }

    var items: [HomeGridItem] { get }

    func load() async
}

@Observable
class PodcastsViewModel: PodcastsViewModelProtocol {
    private var cancellables: Set<AnyCancellable> = []

    private(set) var state: PodcastViewModelState = .loading

    var items: [HomeGridItem] = []

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
        observePodcastUpdates()
    }

    func load() async {
        await fetchPodcasts()
        RefreshManager.shared.refreshPodcasts()
    }

    private func fetchPodcasts() async {
        let gridItems = await Task.detached {
            HomeGridDataHelper.gridItems(orderedBy: .titleAtoZ)
        }.value

        await MainActor.run {
            self.items = gridItems
            self.state = gridItems.isEmpty ? .empty : .ready
        }
    }

    private func observePodcastUpdates() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.podcastUpdated,
            Constants.Notifications.podcastAdded,
            Constants.Notifications.podcastDeleted,
            ServerNotifications.podcastsRefreshed
        ]

        for name in notificationsToObserve {
            NotificationCenter.default.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.fetchPodcasts() }
                }
                .store(in: &cancellables)
        }
    }
}

@Observable
class PodcastsViewModelMock: PodcastsViewModelProtocol {

    private var cancellable: AnyCancellable?

    var state: PodcastViewModelState = .loading

    var items: [HomeGridItem] = []

    func load() async {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                items = MockData.makeStubPodcasts().map { HomeGridItem(podcast: $0) }
                state = items.isEmpty ? .empty : .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
