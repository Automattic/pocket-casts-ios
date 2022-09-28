import Foundation
import PocketCastsServer

extension PodcastViewController {
    func performEpisodeSearch(query: String) {
        guard let podcast = podcast else { return }

        let search = CacheServerHandler.EpisodeSearchQuery(podcastUuid: podcast.uuid, searchTerm: query)
        CacheServerHandler.shared.searchEpisodesInPodcast(search: search) { [weak self] results in
            self?.showSearchResults(results)
        }
    }

    private func showSearchLoading() {}

    func showSearchResults(_ result: CacheServerHandler.EpisodeSearchResult?) {
        searchController?.searchDidComplete()

        guard let podcast = podcast, let result = result else { return }

        uuidsThatMatchSearch.removeAll()

        for episode in result.episodes {
            uuidsThatMatchSearch.append(episode.uuid)
        }

        loadLocalEpisodes(podcast: podcast, animated: true)
    }
}
