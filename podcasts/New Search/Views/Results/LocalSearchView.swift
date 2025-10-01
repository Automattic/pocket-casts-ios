import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct LocalSearchView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchResults: SearchResultsModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var episodes: [EpisodeSearchResult] = []
    @State private var selectedPodcast: Podcast?
    @State private var selectedFolder: Folder?
    @State private var folderPodcasts: [Podcast] = []
    @State private var filteredFolderPodcasts: [Podcast] = []
    @State private var addedEpisodeCount = 0
    @State private var playlistEpisodeUUIDs = Set<String>()
    @State private var isEpisodeSearchInFlight = false
    @State private var currentEpisodeSearchTerm: String = ""
    @State private var currentSearchPodcastUUID: String?

    private let playlist: EpisodeFilter
    private let dismissAction: (() -> Void)?

    init(playlist: EpisodeFilter, dismissAction: (() -> Void)? = nil) {
        self.playlist = playlist
        self.dismissAction = dismissAction
    }

    var body: some View {
        content
            .background(AppTheme.color(for: .primaryUi02, theme: theme).ignoresSafeArea())
            .onAppear {
                loadPodcastsIfNeeded()
                refreshPlaylistEpisodes()
            }
            .onDisappear { searchTask?.cancel() }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: searchPrompt
            )
            .onSubmit(of: .search) {
                triggerImmediateSearch()
            }
            .onChange(of: searchText) { newValue in
                handleSearchTextChange(newValue)
            }
            .onReceive(searchResults.$episodes) { updateEpisodesFromSearchResults($0) }
            .onReceive(searchResults.$episodeSearchError) { handleEpisodeSearchError($0) }
            .toolbar { searchToolbarContent() }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .modify({ view in
                if #available(iOS 17.1, *) {
                    view
                        .searchPresentationToolbarBehavior(.avoidHidingContent)
                } else {
                    view
                }
            })
    }

    private var searchPrompt: Text {
        switch searchMode {
        case .podcasts:
            return Text(L10n.searchPodcasts)
        case .episodes:
            return Text(L10n.localizedFormat("user_episodes_search_episodes_prompt", "Localizable", "Search Episodes"))
        }
    }

    private var content: some View {
        ZStack {
            if searchMode == .podcasts {
                LocalSearchPodcastResultsView(
                    listMode: podcastListMode,
                    selectedFolder: selectedFolder,
                    searchText: searchText,
                    defaultLibraryItems: defaultLibraryItems,
                    folderResults: filteredFolderPodcastResults,
                    hasAnyPodcastsInFolder: !folderPodcasts.isEmpty,
                    searchResults: podcastSearchResults,
                    onSelectResult: { handleSelection(for: $0) }
                )
                .transition(podcastTransition)
            }

            if searchMode == .episodes {
                LocalSearchEpisodeResultsView(
                    isLoading: isEpisodeSearchInFlight,
                    episodes: episodes,
                    searchText: searchText,
                    selectedPodcastTitle: selectedPodcast?.title,
                    onAddEpisode: { handleAddEpisode($0) }
                )
                .transition(episodeTransition)
            }
        }
        .animation(navigationAnimation, value: searchMode)
    }

    private var podcastSearchResults: [PodcastFolderSearchResult] {
        searchResults.podcasts.filter { result in
            (result.kind == .podcast || result.kind == .folder) && (result.isLocal ?? true)
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var podcastListMode: PodcastListMode {
        if selectedFolder != nil {
            return .folder
        }
        if !trimmedSearchText.isEmpty {
            return .search
        }
        return .library
    }

    private var defaultLibraryItems: [PodcastFolderSearchResult] {
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

    private var filteredFolderPodcastResults: [PodcastFolderSearchResult] {
        filteredFolderPodcasts.compactMap { PodcastFolderSearchResult(from: $0) }
    }

    private var searchMode: SearchMode {
        selectedPodcast == nil ? .podcasts : .episodes
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
        let playlistEpisodes = DataManager.sharedManager.playlistEpisodes(for: playlist)
        playlistEpisodeUUIDs = Set(playlistEpisodes.map { $0.uuid })
    }

    private func handleSearchTextChange(_ newValue: String) {
        switch searchMode {
        case .podcasts:
            filterPodcasts(using: newValue)
        case .episodes:
            scheduleEpisodeSearch(with: newValue)
        }
    }

    private func filterPodcasts(using term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        if let _ = selectedFolder {
            if trimmed.isEmpty {
                filteredFolderPodcasts = folderPodcasts
            } else {
                filteredFolderPodcasts = folderPodcasts.filter { podcast in
                    guard let title = podcast.title else { return false }
                    return title.localizedCaseInsensitiveContains(trimmed)
                }
            }
        } else {
            if trimmed.isEmpty {
                searchResults.clearSearch()
            } else {
                searchResults.searchLocally(term: trimmed)
            }
        }
    }

    private func handleSelection(for result: PodcastFolderSearchResult) {
        if result.kind == .folder {
            selectFolder(result)
        } else {
            selectPodcast(result)
        }
    }

    private func selectPodcast(_ podcast: PodcastFolderSearchResult) {
        guard podcast.kind == .podcast,
              let selected = DataManager.sharedManager.findPodcast(uuid: podcast.uuid) else {
            return
        }
        withAnimation(navigationAnimation) {
            enterEpisodeMode(with: selected)
        }
    }

    private func selectFolder(_ folderResult: PodcastFolderSearchResult) {
        guard folderResult.kind == .folder,
              let folder = DataManager.sharedManager.findFolder(uuid: folderResult.uuid) else {
            return
        }

        withAnimation(navigationAnimation) {
            selectedFolder = folder
            selectedPodcast = nil
            clearEpisodeResults()
            loadPodcastsForSelectedFolder(folder)
            searchText = ""
        }
    }

    private func enterEpisodeMode(with podcast: Podcast) {
        selectedPodcast = podcast
        refreshPlaylistEpisodes()
        searchText = ""
        clearEpisodeResults()
        preloadEpisodesForSelectedPodcast()
    }

    private func scheduleEpisodeSearch(with term: String) {
        searchTask?.cancel()

        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, let podcastUuid = selectedPodcast?.uuid else {
            clearEpisodeResults()
            preloadEpisodesForSelectedPodcast()
            return
        }

        isEpisodeSearchInFlight = true

        searchTask = Task { [trimmed, podcastUuid] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performEpisodeSearch(for: trimmed, podcastUuid: podcastUuid)
        }
    }

    private func triggerImmediateSearch() {
        guard searchMode == .episodes else { return }

        searchTask?.cancel()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, let podcastUuid = selectedPodcast?.uuid else {
            clearEpisodeResults()
            preloadEpisodesForSelectedPodcast()
            return
        }

        isEpisodeSearchInFlight = true
        searchTask = Task { [trimmed, podcastUuid] in
            await performEpisodeSearch(for: trimmed, podcastUuid: podcastUuid)
        }
    }

    @MainActor
    private func performEpisodeSearch(for term: String, podcastUuid: String) async {
        guard selectedPodcast?.uuid == podcastUuid else {
            isEpisodeSearchInFlight = false
            return
        }

        currentEpisodeSearchTerm = term
        currentSearchPodcastUUID = podcastUuid
        episodes = []
        searchResults.search(term: term)
    }

    private func updateEpisodesFromSearchResults(_ results: [EpisodeSearchResult]) {
        guard shouldApplySearchResults, let selectedPodcast else { return }

        let filtered = results.filter { $0.podcastUuid == selectedPodcast.uuid }
        let available = filtered.filter { !playlistEpisodeUUIDs.contains($0.uuid) }

        episodes = available
        isEpisodeSearchInFlight = false
    }

    private func handleEpisodeSearchError(_ error: Error?) {
        guard error != nil, shouldApplySearchResults else { return }
        isEpisodeSearchInFlight = false
    }

    private var shouldApplySearchResults: Bool {
        guard searchMode == .episodes,
              let selectedPodcast,
              let currentSearchPodcastUUID,
              currentSearchPodcastUUID == selectedPodcast.uuid else {
            return false
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return false }

        return trimmed == currentEpisodeSearchTerm
    }

    private func clearEpisodeResults() {
        searchTask?.cancel()
        isEpisodeSearchInFlight = false
        episodes = []
        currentEpisodeSearchTerm = ""
        currentSearchPodcastUUID = nil
    }

    private func handleAddEpisode(_ searchResult: EpisodeSearchResult) {
        guard let realEpisode = DataManager.sharedManager.findEpisode(uuid: searchResult.uuid) else {
            assertionFailure("Episode should exist")
            return
        }
        DataManager.sharedManager.add(episodes: [realEpisode], to: playlist)
        playlistEpisodeUUIDs.insert(searchResult.uuid)
        withAnimation {
            episodes.removeAll { $0.uuid == searchResult.uuid }
        }
        addedEpisodeCount += 1
    }

    private func clearSelectedPodcast() {
        withAnimation(navigationAnimation) {
            selectedPodcast = nil
            searchText = ""
        }
        clearEpisodeResults()
        filterPodcasts(using: searchText)
    }

    private func clearSelectedFolder() {
        withAnimation(navigationAnimation) {
            selectedFolder = nil
            searchText = ""
        }
        folderPodcasts = []
        filteredFolderPodcasts = []
        clearEpisodeResults()
        filterPodcasts(using: searchText)
    }

    private var podcastTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .leading)
    }

    private var episodeTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing)
    }

    private var navigationAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.3)
    }

    private func preloadEpisodesForSelectedPodcast() {
        guard let podcast = selectedPodcast else { return }

        let podcastEpisodes = DataManager.sharedManager.allEpisodesForPodcast(id: podcast.id)
        let sortedEpisodes = podcastEpisodes.sorted { lhs, rhs in
            let lhsDate = lhs.publishedDate ?? lhs.addedDate ?? .distantPast
            let rhsDate = rhs.publishedDate ?? rhs.addedDate ?? .distantPast
            return lhsDate > rhsDate
        }

        let excluded = playlistEpisodeUUIDs
        let availableEpisodes = sortedEpisodes.filter { episode in
            !excluded.contains(episode.uuid)
        }

        episodes = availableEpisodes.map { EpisodeSearchResult(episode: $0) }
    }

    private enum SearchMode {
        case podcasts, episodes
    }

}

enum PodcastListMode {
    case library, folder, search
}

private extension LocalSearchView {
    @ToolbarContentBuilder
    func searchToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if selectedPodcast != nil {
                Button {
                    clearSelectedPodcast()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                .accessibilityLabel(L10n.back)
            } else if selectedFolder != nil {
                Button {
                    clearSelectedFolder()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                .accessibilityLabel(L10n.back)
            } else {
                Button {
                    closeModal()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                }
                .accessibilityLabel(L10n.close)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                closeModal()
            } label: {
                Text(L10n.done)
            }
            .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
        }
    }

    func closeModal() {
        if let dismissAction {
            dismissAction()
        } else {
            dismiss()
        }
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
}

private extension EpisodeSearchResult {
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

struct LocalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocalSearchView(playlist: EpisodeFilter())
            .environmentObject(SearchAnalyticsHelper(source: .unknown))
            .environmentObject(SearchHistoryModel(userDefaults: UserDefaults(suiteName: "LocalSearchViewPreview") ?? .standard))
            .previewWithAllThemes()
    }
}
