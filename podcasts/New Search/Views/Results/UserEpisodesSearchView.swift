import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct UserEpisodesSearchView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var searchTokens: [PodcastSearchToken] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @State private var episodes: [EpisodeSearchResult] = []
    @State private var playedEpisodeUUIDs = Set<String>()
    @State private var allPodcasts: [Podcast] = []
    @State private var displayedPodcasts: [Podcast] = []
    @State private var selectedPodcast: Podcast?

    private let episodesDataManager = EpisodesDataManager()
    private let playlistName: String?
    private let dismissAction: (() -> Void)?

    init(playlistName: String? = nil, dismissAction: (() -> Void)? = nil) {
        self.playlistName = playlistName
        self.dismissAction = dismissAction
    }

    var body: some View {
        content
            .background(AppTheme.color(for: .primaryUi02, theme: theme).ignoresSafeArea())
            .onAppear { loadPodcastsIfNeeded() }
            .onDisappear { searchTask?.cancel() }
            .searchable(
                text: $searchText,
                tokens: $searchTokens,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: searchPrompt
            ) { token in
                Text(token.title)
            }
            .onSubmit(of: .search) {
                triggerImmediateSearch()
            }
            .onChange(of: searchText) { newValue in
                handleSearchTextChange(newValue)
            }
            .onChange(of: searchTokens) { newTokens in
                handleSearchTokensChange(newTokens)
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

    @ViewBuilder
    private var content: some View {
        switch searchMode {
        case .podcasts:
            podcastResultsContent
        case .episodes:
            episodeResultsContent
        }
    }

    @ViewBuilder
    private var podcastResultsContent: some View {
        if displayedPodcasts.isEmpty {
            podcastEmptyState
        } else {
            List {
                ForEach(Array(displayedPodcasts.enumerated()), id: \.element.uuid) { index, podcast in
                    if let result = PodcastFolderSearchResult(from: podcast) {
                        SearchResultCell(
                            episode: nil,
                            result: result,
                            played: false,
                            showDivider: index < displayedPodcasts.count - 1,
                            showPodcastSubscribeButton: false,
                            cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01)
                        ) {
                            selectPodcast(podcast)
                        }
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
            Text(L10n.searchPodcasts)
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
                ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                    let played = playedEpisodeUUIDs.contains(episode.uuid)
                    SearchResultCell(
                        episode: episode,
                        result: nil,
                        played: played,
                        showDivider: index < episodes.count - 1,
                        cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01)
                    ) {
                        NavigationManager.sharedManager.navigateTo(
                            NavigationManager.episodePageKey,
                            data: [
                                NavigationManager.episodeUuidKey: episode.uuid,
                                NavigationManager.podcastKey: episode.podcastUuid
                            ]
                        )
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

    private func handleSearchTextChange(_ newValue: String) {
        switch searchMode {
        case .podcasts:
            filterPodcasts(using: newValue)
        case .episodes:
            scheduleEpisodeSearch(with: newValue)
        }
    }

    private func handleSearchTokensChange(_ tokens: [PodcastSearchToken]) {
        guard let firstToken = tokens.first else {
            selectedPodcast = nil
            searchTask?.cancel()
            searchText = ""
            clearEpisodeResults()
            filterPodcasts(using: searchText)
            return
        }

        if tokens.count > 1 {
            searchTokens = [firstToken]
        }

        guard selectedPodcast?.uuid != firstToken.id else { return }

        if let podcast = allPodcasts.first(where: { $0.uuid == firstToken.id }) ?? DataManager.sharedManager.findPodcast(uuid: firstToken.id, includeUnsubscribed: true) {
            enterEpisodeMode(with: podcast, shouldUpdateTokens: false)
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
        enterEpisodeMode(with: podcast, shouldUpdateTokens: true)
    }

    private func enterEpisodeMode(with podcast: Podcast, shouldUpdateTokens: Bool) {
        selectedPodcast = podcast
        if shouldUpdateTokens {
            let token = PodcastSearchToken(podcast: podcast)
            if searchTokens != [token] {
                searchTokens = [token]
            }
        }
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

        episodes = filtered.map { EpisodeSearchResult(listEpisode: $0) }
        playedEpisodeUUIDs = Set(filtered.compactMap { episode in
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

    private func preloadEpisodesForSelectedPodcast() {
        guard let podcast = selectedPodcast else { return }

        let podcastEpisodes = DataManager.sharedManager.allEpisodesForPodcast(id: podcast.id)
        let sortedEpisodes = podcastEpisodes.sorted { lhs, rhs in
            let lhsDate = lhs.publishedDate ?? lhs.addedDate ?? .distantPast
            let rhsDate = rhs.publishedDate ?? rhs.addedDate ?? .distantPast
            return lhsDate > rhsDate
        }

        episodes = sortedEpisodes.map { EpisodeSearchResult(episode: $0) }
        playedEpisodeUUIDs = Set(sortedEpisodes.compactMap { episode in
            episode.played() ? episode.uuid : nil
        })
    }

    private enum SearchMode {
        case podcasts, episodes
    }

    private struct PodcastSearchToken: Identifiable, Hashable {
        let id: String
        let title: String

        init(podcast: Podcast) {
            self.id = podcast.uuid
            self.title = podcast.title ?? ""
        }
    }
}

private extension UserEpisodesSearchView {
    @ToolbarContentBuilder
    func searchToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                closeModal()
            } label: {
                Image("close")
                    .renderingMode(.template)
                    .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
            }
            .accessibilityLabel(L10n.close)
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
        guard let name = playlistName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return L10n.playlistManualAddEpisodes
        }

        return L10n.playlistAddToTitle(name)
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
        UserEpisodesSearchView()
            .environmentObject(SearchAnalyticsHelper(source: .unknown))
            .environmentObject(SearchHistoryModel(userDefaults: UserDefaults(suiteName: "UserEpisodesSearchViewPreview") ?? .standard))
            .previewWithAllThemes()
    }
}
