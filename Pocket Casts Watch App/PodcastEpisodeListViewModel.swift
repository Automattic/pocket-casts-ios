import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class PodcastEpisodeListViewModel: ObservableObject {
    static func createEpisodesQuery(forPodcast podcast: Podcast?) -> String {
        guard let podcast = podcast else { return "" }

        let episodeSortOrder = podcast.podcastSortOrder

        let sortStr: String
        let sortOrder = episodeSortOrder ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .titleAtoZ:
            sortStr = "ORDER BY title ASC, addedDate"
        case .titleZtoA:
            sortStr = "ORDER BY title DESC, addedDate"
        case .newestToOldest:
            sortStr = "ORDER BY publishedDate DESC, addedDate DESC"
        case .oldestToNewest:
            sortStr = "ORDER BY publishedDate ASC, addedDate ASC"
        case .shortestToLongest:
            sortStr = "ORDER BY duration ASC, addedDate"
        case .longestToShortest:
            sortStr = "ORDER BY duration DESC, addedDate"
        }

        return "podcast_id = \(podcast.id) AND archived = 0 \(sortStr) LIMIT \(Constants.Limits.watchListItems)"
    }

    @Published var podcast: Podcast
    @Published var episodes: [EpisodeRowViewModel] = []

    var sortOption: PodcastEpisodeSortOrder {
        let episodeSortOrder = podcast.podcastSortOrder

        return episodeSortOrder ?? .newestToOldest
    }

    private var updatePodcast: AnyPublisher<Notification, Never> {
        Publishers.Merge4(
            Publishers.Notification.podcastUpdated,
            Publishers.Notification.dataUpdated,
            Publishers.Notification.episodeArchiveStatusChanged,
            Publishers.Notification.episodePlayStatusChanged
        )
        .eraseToAnyPublisher()
    }

    init(podcast: Podcast) {
        self.podcast = podcast

        updatePodcast
            .compactMap { [unowned self] _ in
                DataManager.sharedManager.findPodcast(uuid: self.podcast.uuid)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$podcast)

        $podcast
            .compactMap { podcast in
                let query = Self.createEpisodesQuery(forPodcast: podcast)
                return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
                    .map { EpisodeRowViewModel(episode: $0) }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$episodes)
    }

    func didChangeSortOrder(option: PodcastEpisodeSortOrder) {
        if FeatureFlag.newSettingsStorage.enabled {
            podcast.settings.episodesSortOrder = option
            podcast.syncStatus = SyncStatus.notSynced.rawValue
        }
        podcast.episodeSortOrder = option.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }
}
