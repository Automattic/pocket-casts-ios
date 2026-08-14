import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import Combine

@Observable
class PodcastDetailViewModel {

    private let dataManager: TVDataManager
    private let serverPodcastManager: ServerPodcastManager
    private let podcastManager: PodcastManager
    private var cancellables: Set<AnyCancellable> = []

    enum State: Equatable, Hashable {
        case loading
        case ready
        case failed
    }

    var state: State = .loading

    var podcastUuid: String
    var podcast: Podcast?
    var episodes: [EpisodeRowViewModel] = []
    var recommendedEpisode: EpisodeRowViewModel?
    var isFollowing: Bool = false
    var showArchived: Bool = false
    var sortOrder: PodcastEpisodeSortOrder = .newestToOldest
    var isDiscover: Bool

    private static func archiveStorageKey(for podcastUuid: String) -> String {
        "showArchived_podcast_\(podcastUuid)"
    }

    func setShowArchived(_ value: Bool) {
        guard value != showArchived else { return }
        showArchived = value
        load()
        UserDefaults.standard.set(value, forKey: Self.archiveStorageKey(for: podcastUuid))
        Analytics.track(.podcastScreenToggleArchived, properties: ["show_archived": value])
    }

    /// Persists the sort order onto the (synced) podcast like iOS does, then
    /// reloads — `fetchEpisodes` falls back to `podcast.podcastSortOrder`, so the
    /// list comes back in the new order.
    func setSortOrder(_ order: PodcastEpisodeSortOrder) {
        guard order != sortOrder, let podcast else { return }
        podcast.episodeSortOrder = order.old.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        sortOrder = order
        load()
        Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": order])
    }

    init(podcastUuid: String,
         isDiscover: Bool = false,
         dataManager: TVDataManager = TVDataManager.shared,
         serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared,
         podcastManager: PodcastManager = PodcastManager.shared) {
        self.podcastUuid = podcastUuid
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
        self.podcastManager = podcastManager
        self.showArchived = UserDefaults.standard.bool(forKey: Self.archiveStorageKey(for: podcastUuid))
        self.isDiscover = isDiscover
        setupObservers()
    }

    convenience init(podcast: Podcast,
                     dataManager: TVDataManager = TVDataManager.shared,
                     serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared,
                     podcastManager: PodcastManager = PodcastManager.shared) {
        self.init(podcastUuid: podcast.uuid,
                  isDiscover: false,
                  dataManager: dataManager,
                  serverPodcastManager: serverPodcastManager,
                  podcastManager: podcastManager)
        self.podcast = podcast
    }

    func load() {
        Task {
            var podcast: Podcast? = self.podcast
            if podcast == nil {
                podcast = await dataManager.loadPodcast(podcastUuid: podcastUuid)
            }
            guard let podcast else {
                await MainActor.run { state = .failed }
                return
            }
            let allEpisodes = await dataManager.fetchEpisodes(podcast: podcast, includeArchived: showArchived).map {
                EpisodeRowViewModel(episode: $0, podcast: podcast, isDiscover: isDiscover, source: .podcastScreen)
            }
            await MainActor.run {
                self.podcast = podcast
                self.isFollowing = podcast.subscribed != 0
                self.episodes = allEpisodes
                self.recommendedEpisode = nil
                self.sortOrder = podcast.podcastSortOrder ?? .newestToOldest
                self.state = .ready
            }
        }
    }

    func subscribe() {
        guard let podcast else { return }
        Analytics.track(.podcastScreenSubscribeTapped)
        Analytics.track(.podcastSubscribed, properties: ["source": "podcast_screen", "uuid": podcast.uuid])
        if isDiscover {
            DiscoverAnalytics.discoverPodcastSubscribed(podcastUuid: podcast.uuid)
        }
        isFollowing = true
        serverPodcastManager.subscribe(to: podcast.uuid, completion: nil)
    }

    func unsubscribe() {
        guard let podcast else { return }
        Analytics.track(.podcastScreenUnsubscribeTapped)
        Analytics.track(.podcastUnsubscribed, properties: ["source": "podcast_screen", "uuid": podcast.uuid])
        isFollowing = false
        podcastManager.unsubscribe(podcast: podcast)
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: Constants.Notifications.episodeArchiveStatusChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self else {
                return
            }
            if let uuid = notification.object as? String {
                let contains = episodes.contains { episode in
                    episode.id == uuid
                }
                if contains {
                    load()
                }
            }
        }
        .store(in: &cancellables)
    }
}
