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
    @Published private(set) var searchResultsPodcasts: [PodcastFolderSearchResult] = []
    @Published private(set) var disableLibraryAnimation = false

    let playlist: EpisodeFilter

    private var cancellables = Set<AnyCancellable>()
    private var searchResultsModel: SearchResultsModel?
    private var episodeCoordinator: LocalSearchCoordinator?
    private var hasAppeared = false

    private struct PodcastSearchState {
        let term: String
        let results: [PodcastFolderSearchResult]
    }

    private var previouslySelectedFolder: Folder?
    private var previousPodcastSearchState: PodcastSearchState?
    private var folderSearchStateStack: [PodcastSearchState] = []

    init(playlist: EpisodeFilter) {
        self.playlist = playlist

        $searchText
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.handleSearchTextChange(newValue)
            }
            .store(in: &cancellables)
    }

    var searchMode: SearchMode {
        selectedPodcast == nil ? .podcasts : .episodes
    }

    var podcastListMode: PodcastListMode {
        if selectedFolder != nil {
            return .folder
        }
        if !trimmedSearchText.isEmpty || previousPodcastSearchState != nil || !folderSearchStateStack.isEmpty {
            return .search
        }
        return .library
    }

    var rootListMode: PodcastListMode {
        if !trimmedSearchText.isEmpty || previousPodcastSearchState != nil || !folderSearchStateStack.isEmpty {
            return .search
        }
        return .library
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
        configureSearchResultsIfNeeded(searchResultsModel)
        guard !hasAppeared else { return }
        hasAppeared = true
        loadPodcastsIfNeeded()
        refreshPlaylistEpisodes()
    }

    func onDisappear() {
        episodeCoordinator?.cancelPendingSearch()
    }

    func podcast(from result: PodcastFolderSearchResult) -> Podcast? {
        guard result.kind == .podcast,
              let podcast = DataManager.sharedManager.findPodcast(uuid: result.uuid) else {
            return nil
        }
        return podcast
    }

    func beginEpisodeMode(with podcast: Podcast) {
        previousPodcastSearchState = currentSearchState()
        previouslySelectedFolder = selectedFolder
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

        if let searchState = currentSearchState() {
            folderSearchStateStack.append(searchState)
        }

        selectedFolder = folder
        previouslySelectedFolder = folder
        selectedPodcast = nil
        episodeCoordinator?.clearResults()
        loadPodcastsForSelectedFolder(folder)
        if !trimmedSearchText.isEmpty {
            searchText = ""
        } else {
            filterPodcasts(using: searchText)
        }
    }

    func clearSelectedPodcast() {
        let searchState = previousPodcastSearchState
        selectedPodcast = nil
        if let folder = previouslySelectedFolder {
            selectedFolder = folder
            loadPodcastsForSelectedFolder(folder)
            let restoreTerm = searchState?.term ?? ""
            if searchText != restoreTerm {
                searchText = restoreTerm
            } else {
                filterPodcasts(using: restoreTerm)
            }
        } else if let searchState, !searchState.term.isEmpty {
            selectedFolder = nil
            searchResultsPodcasts = searchState.results
            if searchText != searchState.term {
                searchText = searchState.term
            } else {
                filterPodcasts(using: searchState.term)
            }
        } else {
            selectedFolder = nil
            if !searchText.isEmpty {
                searchText = ""
            }
            filterPodcasts(using: "")
        }
        DispatchQueue.main.async { [weak self] in
            self?.episodeCoordinator?.clearResults()
        }
        previousPodcastSearchState = nil
    }

    func clearSelectedFolder() {
        selectedFolder = nil
        folderPodcasts = []
        filteredFolderPodcasts = []
        if let previousState = folderSearchStateStack.popLast() {
            searchResultsPodcasts = previousState.results
            if searchText != previousState.term {
                searchText = previousState.term
            } else {
                filterPodcasts(using: previousState.term)
            }
        } else {
            searchText = ""
            filterPodcasts(using: searchText, disableAnimationsWhenClearing: false)
        }
        DispatchQueue.main.async { [weak self] in
            self?.episodeCoordinator?.clearResults()
        }
        previouslySelectedFolder = nil
    }

    func triggerImmediateSearch() {
        guard searchMode == .episodes,
              let coordinator = episodeCoordinator else { return }

        let trimmed = trimmedSearchText
        guard let podcastUuid = selectedPodcast?.uuid, trimmed.count >= 2 else {
            coordinator.clearResults()
            coordinator.preloadEpisodes(for: selectedPodcast)
            return
        }

        coordinator.triggerImmediateSearch(for: trimmed, podcastUuid: podcastUuid)
    }

    func handleAddEpisode(_ searchResult: EpisodeSearchResult) {
        episodeCoordinator?.handleAddEpisode(searchResult)
    }

    private func configureSearchResultsIfNeeded(_ searchResultsModel: SearchResultsModel) {
        guard self.searchResultsModel !== searchResultsModel else { return }
        self.searchResultsModel = searchResultsModel
        configureEpisodeCoordinatorIfNeeded(using: searchResultsModel)

        searchResultsModel.$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self else { return }
                self.searchResultsPodcasts = results.filter { result in
                    (result.kind == .podcast || result.kind == .folder) && (result.isLocal ?? true)
                }
            }
            .store(in: &cancellables)

        searchResultsModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.updateEpisodesFromSearchResults(results)
            }
            .store(in: &cancellables)

        searchResultsModel.$episodeSearchError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleEpisodeSearchError(error)
            }
            .store(in: &cancellables)
    }

    private func configureEpisodeCoordinatorIfNeeded(using searchResultsModel: SearchResultsModel) {
        guard episodeCoordinator == nil else { return }

        let coordinator = LocalSearchCoordinator(
            playlist: playlist,
            searchResultsModel: searchResultsModel
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

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadPodcastsIfNeeded() {
        filterPodcasts(using: searchText)
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

    private func refreshPlaylistEpisodes() {
        episodeCoordinator?.refreshPlaylistEpisodes()
    }

    private func handleSearchTextChange(_ newValue: String) {
        switch searchMode {
        case .podcasts:
            filterPodcasts(using: newValue)
        case .episodes:
            scheduleEpisodeSearch(with: newValue)
        }
    }

    private func filterPodcasts(using term: String, disableAnimationsWhenClearing: Bool = true) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)

        if selectedFolder != nil {
            if trimmed.isEmpty {
                filteredFolderPodcasts = folderPodcasts
            } else {
                filteredFolderPodcasts = folderPodcasts.filter { podcast in
                    guard let title = podcast.title else { return false }
                    return title.localizedCaseInsensitiveContains(trimmed)
                }
            }
        } else {
            guard let searchResultsModel else { return }
            if trimmed.isEmpty {
                if disableAnimationsWhenClearing {
                    disableLibraryAnimation = true
                }
                let transaction = disableAnimationsWhenClearing ? Transaction(animation: nil) : Transaction()
                withTransaction(transaction) {
                    searchResultsModel.clearSearch()
                }
                if disableAnimationsWhenClearing {
                    DispatchQueue.main.async { [weak self] in
                        self?.disableLibraryAnimation = false
                    }
                }
            } else {
                searchResultsModel.searchLocally(term: trimmed)
            }
        }
    }

    private func scheduleEpisodeSearch(with term: String) {
        guard let coordinator = episodeCoordinator else { return }

        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let podcastUuid = selectedPodcast?.uuid, trimmed.count >= 2 else {
            coordinator.clearResults()
            coordinator.preloadEpisodes(for: selectedPodcast)
            return
        }

        coordinator.scheduleSearch(for: trimmed, podcastUuid: podcastUuid)
    }

    private func updateEpisodesFromSearchResults(_ results: [EpisodeSearchResult]) {
        episodeCoordinator?.updateEpisodesFromSearchResults(
            results,
            selectedPodcastUUID: selectedPodcast?.uuid,
            trimmedSearchText: trimmedSearchText
        )
    }

    private func handleEpisodeSearchError(_ error: Error?) {
        episodeCoordinator?.handleSearchError(
            error,
            selectedPodcastUUID: selectedPodcast?.uuid,
            trimmedSearchText: trimmedSearchText
        )
    }
}

extension EpisodeSearchResult {
    init(episode: Episode, dataManager: DataManager = DataManager.sharedManager) {
        let publishedDate = episode.publishedDate ?? episode.addedDate ?? Date()
        let duration = episode.duration > 0 ? episode.duration : nil
        let podcastTitle = episode.parentPodcast(dataManager: dataManager)?.title ?? ""

        self.init(uuid: episode.uuid, title: episode.displayableTitle(), publishedDate: publishedDate, duration: duration, podcastUuid: episode.podcastUuid, podcastTitle: podcastTitle)
    }

    init(listEpisode: ListEpisode, dataManager: DataManager = DataManager.sharedManager) {
        self.init(episode: listEpisode.episode, dataManager: dataManager)
    }
}

extension LocalSearchViewModel {
    enum SearchMode {
        case podcasts
        case episodes
    }

    private func currentSearchState() -> PodcastSearchState? {
        let trimmed = trimmedSearchText
        guard !trimmed.isEmpty else { return nil }
        return PodcastSearchState(term: trimmed, results: searchResultsPodcasts)
    }
}
