import SwiftUI
import Combine
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

@MainActor
final class LocalSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var episodes: [EpisodeSearchResult] = []
    @Published private(set) var selectedPodcast: Podcast?
    @Published private(set) var selectedFolder: Folder?
    @Published private(set) var folderPodcasts: [Podcast] = []
    @Published private(set) var filteredFolderPodcasts: [Podcast] = []
    @Published private(set) var isEpisodeSearchInFlight = false
    @Published private(set) var addedEpisodeCount = 0

    let playlist: EpisodeFilter

    private var episodeCoordinator: LocalSearchCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var hasAppeared = false

    init(playlist: EpisodeFilter) {
        self.playlist = playlist
    }

    var searchMode: SearchMode {
        selectedPodcast == nil ? .podcasts : .episodes
    }

    var podcastListMode: PodcastListMode {
        selectedFolder == nil ? .library : .folder
    }

    var rootListMode: PodcastListMode {
        selectedFolder == nil ? .library : .folder
    }

    var defaultLibraryItems: [PodcastFolderSearchResult] {
        let sortOrder = Settings.homeFolderSortOrder()
        let items = HomeGridDataHelper.gridItems(orderedBy: sortOrder)
        return items.compactMap { item in
            if let podcast = item.podcast {
                return PodcastFolderSearchResult(from: podcast)
            }
            if let folder = item.folder {
                return PodcastFolderSearchResult(from: folder)
            }
            return nil
        }
    }

    var filteredFolderPodcastResults: [PodcastFolderSearchResult] {
        filteredFolderPodcasts.compactMap { PodcastFolderSearchResult(from: $0) }
    }

    var hasAnyPodcastsInFolder: Bool {
        !folderPodcasts.isEmpty
    }

    var searchResultsPodcasts: [PodcastFolderSearchResult] {
        []
    }

    var disableLibraryAnimation: Bool {
        false
    }

    var navigationTitle: String {
        let name = playlist.playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard addedEpisodeCount > 0 else {
            return L10n.playlistAddToTitle(name)
        }

        if addedEpisodeCount == 1 {
            let format = L10n.localizedFormat("playlist_episode_added_title", "Localizable", "1 episode added to \"%@\"")
            return String(format: format, locale: Locale.current, name)
        } else {
            let format = L10n.localizedFormat("playlist_episodes_added_title", "Localizable", "%1$@ episodes added to \"%2$@\"")
            return String(format: format, locale: Locale.current, addedEpisodeCount.localized(), name)
        }
    }

    func onAppear(searchResultsModel: SearchResultsModel) {
        configureEpisodeCoordinatorIfNeeded()
        guard !hasAppeared else { return }
        hasAppeared = true
        refreshPlaylistEpisodes()
    }

    func onDisappear() {
        episodeCoordinator?.clearResults()
    }

    func podcast(from result: PodcastFolderSearchResult) -> Podcast? {
        guard result.kind == .podcast,
              let podcast = DataManager.sharedManager.findPodcast(uuid: result.uuid) else {
            return nil
        }
        return podcast
    }

    func beginEpisodeMode(with podcast: Podcast) {
        selectedPodcast = podcast
        searchText = ""
        episodeCoordinator?.clearResults()
        episodeCoordinator?.refreshPlaylistEpisodes()
        episodeCoordinator?.preloadEpisodes(for: selectedPodcast)
    }

    func selectPodcast(_ podcastResult: PodcastFolderSearchResult) {
        guard let podcast = podcast(from: podcastResult) else { return }
        beginEpisodeMode(with: podcast)
    }

    func selectFolder(_ folderResult: PodcastFolderSearchResult) {
        guard folderResult.kind == .folder,
              let folder = DataManager.sharedManager.findFolder(uuid: folderResult.uuid) else {
            return
        }
        selectedFolder = folder
        selectedPodcast = nil
        loadPodcastsForSelectedFolder(folder)
        episodeCoordinator?.clearResults()
    }

    func clearSelectedPodcast() {
        selectedPodcast = nil
        episodeCoordinator?.clearResults()
        episodeCoordinator?.preloadEpisodes(for: nil)
    }

    func clearSelectedFolder() {
        selectedFolder = nil
        folderPodcasts = []
        filteredFolderPodcasts = []
    }

    func triggerImmediateSearch() {
        episodeCoordinator?.preloadEpisodes(for: selectedPodcast)
    }

    func handleAddEpisode(_ searchResult: EpisodeSearchResult) {
        episodeCoordinator?.handleAddEpisode(searchResult)
        addedEpisodeCount = episodeCoordinator?.addedEpisodeCount ?? 0
    }

    private func configureEpisodeCoordinatorIfNeeded() {
        guard episodeCoordinator == nil else { return }

        let coordinator = LocalSearchCoordinator(
            playlist: playlist
        )

        coordinator.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.episodes = $0 }
            .store(in: &cancellables)

        coordinator.$isSearchInFlight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isEpisodeSearchInFlight = $0 }
            .store(in: &cancellables)

        coordinator.$addedEpisodeCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.addedEpisodeCount = $0 }
            .store(in: &cancellables)

        episodeCoordinator = coordinator
        episodeCoordinator?.refreshPlaylistEpisodes()
        episodeCoordinator?.preloadEpisodes(for: selectedPodcast)
    }

    private func refreshPlaylistEpisodes() {
        episodeCoordinator?.refreshPlaylistEpisodes()
    }

    private func loadPodcastsForSelectedFolder(_ folder: Folder) {
        let podcasts = DataManager.sharedManager.allPodcastsInFolder(folder: folder)
        let sorted = podcasts.sorted { lhs, rhs in
            let lhsTitle = lhs.title ?? ""
            let rhsTitle = rhs.title ?? ""
            return lhsTitle.localizedCaseInsensitiveCompare(rhsTitle) == .orderedAscending
        }

        folderPodcasts = sorted
        filteredFolderPodcasts = sorted
    }

}

extension LocalSearchViewModel {
    enum SearchMode {
        case podcasts
        case episodes
    }
}
