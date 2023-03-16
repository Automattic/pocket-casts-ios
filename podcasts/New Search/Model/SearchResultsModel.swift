import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

class SearchResultsModel: ObservableObject {
    private let podcastSearch = PodcastSearchTask()
    private let episodeSearch = EpisodeSearchTask()

    @Published var isSearchingForPodcasts = false
    @Published var isSearchingForEpisodes = false

    @Published var podcasts: [PodcastFolderSearchResult] = []
    @Published var episodes: [EpisodeSearchResult] = []

    @Published var isShowingLocalResultsOnly = false

    func clearSearch() {
        podcasts = []
        episodes = []
    }

    @MainActor
    func search(term: String) {
        if !isShowingLocalResultsOnly {
            clearSearch()
        }

        Task {
            isSearchingForPodcasts = true
            let results = try? await podcastSearch.search(term: term)
            isSearchingForPodcasts = false
            show(podcastResults: results ?? [])
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
        clearSearch()

        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

        var results = [PodcastFolderSearchResult?]()
        for podcast in allPodcasts {
            guard let title = podcast.title else { continue }

            if title.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastFolderSearchResult(from: podcast))
            } else if let author = podcast.author, author.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastFolderSearchResult(from: podcast))
            }
        }

        if SubscriptionHelper.hasActiveSubscription() {
            let allFolders = DataManager.sharedManager.allFolders()
            for folder in allFolders {
                if folder.name.localizedCaseInsensitiveContains(searchTerm) {
                    results.append(PodcastFolderSearchResult(from: folder))
                }
            }
        }

        self.podcasts = results.compactMap { $0 }

        isShowingLocalResultsOnly = true
    }

    private func show(podcastResults: [PodcastFolderSearchResult]) {
        if isShowingLocalResultsOnly {
            podcasts.append(contentsOf: podcastResults.filter { !podcasts.contains($0) })
            isShowingLocalResultsOnly = false
        } else {
            podcasts = podcastResults
        }
    }
}
