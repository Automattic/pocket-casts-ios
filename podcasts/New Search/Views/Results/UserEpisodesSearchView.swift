import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct UserEpisodesSearchView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @State private var episodes: [EpisodeSearchResult] = []
    @State private var playedEpisodeUUIDs = Set<String>()
    @State private var allPodcasts: [Podcast] = []
    @State private var displayedPodcasts: [Podcast] = []
    @State private var selectedPodcast: Podcast?
    @State private var addedEpisodeCount = 0
    @State private var playlistEpisodeUUIDs = Set<String>()

    private let episodesDataManager = EpisodesDataManager()
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
            return Text(L10n.search)
        }
    }

    private var content: some View {
        ZStack {
            if searchMode == .podcasts {
                podcastResultsContent
                    .transition(podcastTransition)
            }

            if searchMode == .episodes {
                episodeResultsContent
                    .transition(episodeTransition)
            }
        }
        .animation(navigationAnimation, value: searchMode)
    }

    @ViewBuilder
    private var podcastResultsContent: some View {
        if displayedPodcasts.isEmpty {
            podcastEmptyState
        } else {
            List {
                Text(L10n.localizedFormat("user_episodes_search_podcasts_title", "Localizable", "Your Podcasts"))
                    .font(style: .headline, weight: .semibold)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                ForEach(Array(displayedPodcasts.enumerated()), id: \.element.uuid) { index, podcast in
                    if let result = PodcastFolderSearchResult(from: podcast) {
                        SearchResultCell(
                            episode: nil,
                            result: result,
                            played: false,
                            showDivider: index < displayedPodcasts.count - 1,
                            showPodcastSubscribeButton: false,
                            cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01),
                            action: {
                            selectPodcast(podcast)
                        })
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var podcastEmptyState: some View {
        VStack(spacing: 12) {
            Text(L10n.localizedFormat("user_episodes_search_podcasts_title", "Localizable", "Your Podcasts"))
                .font(style: .title3, weight: .semibold)
                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
            Text(L10n.listeningHistorySearchNoEpisodesText)
                .multilineTextAlignment(.center)
                .font(style: .body)
                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 48)
    }

    @ViewBuilder
    private var episodeResultsContent: some View {
        if isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(AppTheme.loadingActivityColor().color)
        } else if episodes.isEmpty {
            episodesEmptyState
        } else {
            List {
                ForEach(Array(episodes.enumerated()), id: \.element) { index, searchResult in
                    let played = playedEpisodeUUIDs.contains(searchResult.uuid)
                    SearchResultCell(
                        episode: searchResult,
                        result: nil,
                        played: played,
                        showDivider: index < episodes.count - 1,
                        showEpisodeAddButton: true,
                        cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01)) {
                            guard let realEpisode = DataManager.sharedManager.findEpisode(uuid: searchResult.uuid) else {
                                assertionFailure("Episode should exist")
                                return
                            }
                            DataManager.sharedManager.add(episodes: [realEpisode], to: playlist)
                            playlistEpisodeUUIDs.insert(searchResult.uuid)
                            withAnimation {
                                episodes.removeAll { $0.uuid == searchResult.uuid }
                                playedEpisodeUUIDs.remove(searchResult.uuid)
                            }
                            addedEpisodeCount += 1
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var episodesEmptyState: some View {
        VStack(spacing: 12) {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count < 2 {
                Text(selectedPodcast?.title ?? L10n.search)
                    .font(style: .title3, weight: .semibold)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                Text(L10n.listeningHistorySearchNoEpisodesText)
                    .multilineTextAlignment(.center)
                    .font(style: .body)
                    .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                    .padding(.horizontal, 32)
            } else {
                EmptyStateView(
                    title: L10n.listeningHistorySearchNoEpisodesTitle,
                    message: L10n.listeningHistorySearchNoEpisodesText,
                    icon: { Image(systemName: "info.circle") }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 48)
    }

    private var searchMode: SearchMode {
        selectedPodcast == nil ? .podcasts : .episodes
    }

    private func loadPodcastsIfNeeded() {
        guard allPodcasts.isEmpty else { return }
        let podcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()
        allPodcasts = podcasts
        displayedPodcasts = podcasts
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
        if trimmed.isEmpty {
            displayedPodcasts = allPodcasts
        } else {
            displayedPodcasts = DataManager.sharedManager.searchPodcasts(term: trimmed)
        }
    }

    private func selectPodcast(_ podcast: Podcast) {
        withAnimation(navigationAnimation) {
            enterEpisodeMode(with: podcast)
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

        isSearching = true

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

        isSearching = true
        searchTask = Task { [trimmed, podcastUuid] in
            await performEpisodeSearch(for: trimmed, podcastUuid: podcastUuid)
        }
    }

    @MainActor
    private func performEpisodeSearch(for term: String, podcastUuid: String) async {
        guard selectedPodcast?.uuid == podcastUuid else {
            isSearching = false
            return
        }

        let sections = episodesDataManager.searchEpisodes(for: term, listenedTo: false)
        let listEpisodes = sections.flatMap { $0.elements }
        let filtered = listEpisodes.filter { $0.episode.podcastUuid == podcastUuid }
        let availableListEpisodes = filtered.filter { listEpisode in
            !playlistEpisodeUUIDs.contains(listEpisode.episode.uuid)
        }

        episodes = availableListEpisodes.map { EpisodeSearchResult(listEpisode: $0) }
        playedEpisodeUUIDs = Set(availableListEpisodes.compactMap { episode in
            episode.episode.played() ? episode.episode.uuid : nil
        })
        isSearching = false
    }

    private func clearEpisodeResults() {
        searchTask?.cancel()
        isSearching = false
        episodes = []
        playedEpisodeUUIDs.removeAll()
    }

    private func clearSelectedPodcast() {
        withAnimation(navigationAnimation) {
            selectedPodcast = nil
            searchText = ""
        }
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
        playedEpisodeUUIDs = Set(availableEpisodes.compactMap { episode in
            episode.played() ? episode.uuid : nil
        })
    }

    private enum SearchMode {
        case podcasts, episodes
    }

}

private extension UserEpisodesSearchView {
    @ToolbarContentBuilder
    func searchToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if selectedPodcast == nil {
                Button {
                    closeModal()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                }
                .accessibilityLabel(L10n.close)
            } else {
                Button {
                    clearSelectedPodcast()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
                .accessibilityLabel(L10n.back)
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

struct UserEpisodesSearchView_Previews: PreviewProvider {
    static var previews: some View {
        UserEpisodesSearchView(playlist: EpisodeFilter())
            .environmentObject(SearchAnalyticsHelper(source: .unknown))
            .environmentObject(SearchHistoryModel(userDefaults: UserDefaults(suiteName: "UserEpisodesSearchViewPreview") ?? .standard))
            .previewWithAllThemes()
    }
}
