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

    var sortOrder: LibrarySort { get }

    func load() async

    func setSortOrder(_ order: LibrarySort)
}

extension LibrarySort {
    /// The sort options offered on the podcasts list, in the same order as the iOS app.
    static let podcastsListOptions: [LibrarySort] = [
        .dateAddedNewestToOldest,
        .episodeDateNewestToOldest,
        .recentlyPlayed,
        .titleAtoZ,
        .custom
    ]
}

@Observable
class PodcastsViewModel: PodcastsViewModelProtocol {
    private var cancellables: Set<AnyCancellable> = []

    private(set) var state: PodcastViewModelState = .loading

    var items: [HomeGridItem] = []

    private(set) var sortOrder: LibrarySort = Settings.homeFolderSortOrder

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        observePodcastUpdates()
    }

    func load() async {
        await fetchPodcasts()
        RefreshManager.shared.refreshPodcasts()
    }

    /// Persists the sort order to the (synced) setting shared with the iOS app, then reloads the grid.
    func setSortOrder(_ order: LibrarySort) {
        guard order != sortOrder else { return }
        Settings.homeFolderSortOrder = order
        sortOrder = order
        Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": order])
        Task { await fetchPodcasts() }
    }

    private func fetchPodcasts() async {
        // Re-read the setting, a sync may have changed it from another device.
        let order = Settings.homeFolderSortOrder
        let gridItems = await Task {
            HomeGridDataHelper.gridItems(orderedBy: order)
        }.value

        await MainActor.run {
            self.sortOrder = order
            self.items = gridItems
            self.state = gridItems.isEmpty ? .empty : .ready
        }
    }

    private func observePodcastUpdates() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.podcastUpdated,
            Constants.Notifications.podcastAdded,
            Constants.Notifications.podcastDeleted,
            ServerNotifications.podcastsRefreshed,
            ServerNotifications.syncCompleted
        ]

        let publishers = notificationsToObserve.map {
            NotificationCenter.default.publisher(for: $0).map { _ in () }.eraseToAnyPublisher()
        }

        Publishers.MergeMany(publishers)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.fetchPodcasts() }
            }
            .store(in: &cancellables)
    }
}

@Observable
class PodcastsViewModelMock: PodcastsViewModelProtocol {

    private var cancellable: AnyCancellable?

    var state: PodcastViewModelState = .loading

    var items: [HomeGridItem] = []

    var sortOrder: LibrarySort = .dateAddedNewestToOldest

    func setSortOrder(_ order: LibrarySort) {
        sortOrder = order
    }

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
