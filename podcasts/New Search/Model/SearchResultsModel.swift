import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

class SearchResultsModel: ObservableObject {
    private let podcastSearch = PodcastSearchTask()
    private let episodeSearch = EpisodeSearchTask()

    @Published var isSearchingForPodcasts = false
    @Published var isSearchingForEpisodes = false

    @Published var podcasts: [PodcastSearchResult] = []
    @Published var episodes: [EpisodeSearchResult] = []

    func clearSearch() {
        podcasts = []
        episodes = []
    }

    @MainActor
    func search(term: String) {
        clearSearch()

        Task {
            isSearchingForPodcasts = true
            let results = try? await podcastSearch.search(term: term)
            isSearchingForPodcasts = false
            podcasts = results ?? []
        }

        Task {
            isSearchingForEpisodes = true
            let results = try? await episodeSearch.search(term: term)
            isSearchingForEpisodes = false
            episodes = results ?? []
        }
    }

    @MainActor
    func searchLocally(term searchTerm: String) {
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

        var results = [PodcastSearchResult?]()
        for podcast in allPodcasts {
            guard let title = podcast.title else { continue }

            if title.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastSearchResult(from: podcast))
            } else if let author = podcast.author, author.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastSearchResult(from: podcast))
            }
        }

        self.podcasts = results.compactMap { $0 }
    }
}
