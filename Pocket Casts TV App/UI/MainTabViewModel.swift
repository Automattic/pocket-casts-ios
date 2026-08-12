import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@MainActor
@Observable
final class MainTabViewModel {
    private var cancellables: Set<AnyCancellable> = []

    var selectedTab: MainTab = .home
    var isShowingDetail: Bool = false
    var pendingAuthFlow: ProfileMenuView.AuthDestination?
    var profileDestination: ProfileMenuView.ProfileDestination?
    var showFullScreenPlayer: Bool = false

    var scrollOffset: CGFloat = 0

    var currentPlayingEpisode: BaseEpisode?

    var homeModel = HomeViewModel()
    var myPodcastsModel = PodcastsViewModel()
    var playlistsModel = PlaylistsViewModel()
    var upNextModel = UpNextViewModel()
    var searchViewModel = SearchViewModel()
    var discoverAllViewModel = DiscoverAllViewModel(type: .search)
    var discoverHomeSignedInViewModel = DiscoverAllViewModel(type: .signedIn)
    var discoverHomeSignedOutViewModel = DiscoverAllViewModel(type: .signedOut)

    init() {
        currentPlayingEpisode = PlaybackManager.shared.currentEpisode
        observeUpNextChanges()
    }

    func shouldShowTab(_ tab: MainTab) -> Bool {
        switch tab {
        case .nowPlaying:
            return currentPlayingEpisode != nil
        default:
            return true
        }
    }

    fileprivate func observeUpNextChanges() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.upNextQueueChanged,
            Constants.Notifications.upNextEpisodeRemoved,
            Constants.Notifications.upNextEpisodeAdded,
        ]

        let publishers = notificationsToObserve.map {
            NotificationCenter.default.publisher(for: $0).map { _ in () }.eraseToAnyPublisher()
        }

        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                currentPlayingEpisode = PlaybackManager.shared.currentEpisode
                if currentPlayingEpisode == nil, selectedTab == .nowPlaying {
                     selectedTab = .home
                     isShowingDetail = false
                 }
            }
            .store(in: &cancellables)
    }
}
