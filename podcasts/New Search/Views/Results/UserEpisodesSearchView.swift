import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct UserEpisodesSearchView: View {
    @EnvironmentObject var theme: Theme

    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @State private var episodes: [EpisodeSearchResult] = []
    @State private var playedEpisodeUUIDs = Set<String>()

    private let episodesDataManager = EpisodesDataManager()

    var body: some View {
        VStack(spacing: 0) {
            searchField
            resultsContent
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme).ignoresSafeArea())
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
            TextField(L10n.search, text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit { triggerImmediateSearch() }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
                }
                .accessibilityLabel(L10n.clearSearch)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.color(for: .primaryField01, theme: theme))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .onChange(of: searchText) { newValue in
            scheduleSearch(with: newValue)
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        if isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(AppTheme.loadingActivityColor().color)
        } else if episodes.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                        let played = playedEpisodeUUIDs.contains(episode.uuid)
                        SearchResultCell(
                            episode: episode,
                            result: nil,
                            played: played,
                            showDivider: index < episodes.count - 1,
                            cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01),
                            action: {
                                NavigationManager.sharedManager.navigateTo(
                                    NavigationManager.episodePageKey,
                                    data: [
                                        NavigationManager.episodeUuidKey: episode.uuid,
                                        NavigationManager.podcastKey: episode.podcastUuid
                                    ]
                                )
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(AppTheme.color(for: .primaryUi02, theme: theme))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                Text(L10n.search)
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

    private func scheduleSearch(with term: String) {
        searchTask?.cancel()

        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            clearResults()
            return
        }

        isSearching = true

        searchTask = Task { [trimmed] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(for: trimmed)
        }
    }

    private func triggerImmediateSearch() {
        searchTask?.cancel()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            clearResults()
            return
        }

        isSearching = true
        searchTask = Task {
            await performSearch(for: trimmed)
        }
    }

    @MainActor
    private func performSearch(for term: String) async {
        let sections = episodesDataManager.searchEpisodes(for: term, listenedTo: false )
        let listEpisodes = sections.flatMap { $0.elements }
        episodes = listEpisodes.map { EpisodeSearchResult(listEpisode: $0) }
        playedEpisodeUUIDs = Set(listEpisodes.compactMap { $0.episode.played() ? $0.episode.uuid : nil })
        isSearching = false
    }

    private func clearResults() {
        searchTask?.cancel()
        isSearching = false
        episodes = []
        playedEpisodeUUIDs.removeAll()
    }
}

private extension EpisodeSearchResult {
    init(listEpisode: ListEpisode, dataManager: DataManager = DataManager.sharedManager) {
        let episode = listEpisode.episode
        let publishedDate = episode.publishedDate ?? episode.addedDate ?? Date()
        let duration = episode.duration > 0 ? episode.duration : nil
        let podcastTitle = episode.parentPodcast(dataManager: dataManager)?.title ?? ""

        self.init(uuid: episode.uuid, title: episode.displayableTitle(), publishedDate: publishedDate, duration: duration, podcastUuid: episode.podcastUuid, podcastTitle: podcastTitle)
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
