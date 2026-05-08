import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils
import PocketCastsServer

struct NewSearchResultsView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State var identifier = 0

    @State var showInlineResults = false
    @State var displayMode: SearchResultsListView.DisplayMode = .allResults

    var body: some View {
        Group {
            if (searchResults.podcastSearchError != nil || searchResults.predictiveSearchError != nil) && !searchResults.resultsContainLocalPodcasts {
                HStack(alignment: .center) {
                    EmptyStateView(
                        title: L10n.discoverSearchFailed,
                        message: L10n.discoverSearchFailedMsg,
                        icon: { Image("no-connection-grey").renderingMode(.template) },
                        actions: [
                            .init(title: L10n.tryAgain, style: SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01)) {
                                searchResults.search(term: searchResults.currentSearchTerm)
                            }
                        ]
                    )
                }
                .frame(maxHeight: .infinity)
                .background(Theme.sharedTheme.primaryUi01)
            } else if searchResults.isSearchingForEpisodes || searchResults.isSearchingForPodcasts || (searchResults.isSearchingPredictive && searchResults.predictive.isEmpty) {
                  ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(AppTheme.loadingActivityColor().color)
            } else if searchResults.noResults {
                if searchResults.isShowingPredictiveSearch {
                    VStack {
                        Spacer()
                    }
                    .background(Theme.sharedTheme.primaryUi01)
                } else {
                    HStack(alignment: .center) {
                        EmptyStateView(title: L10n.searchResultsEmptyTitle,
                                       message: L10n.searchResultsEmptyMessage,
                                       icon: { Image("search") },
                                       actions: []
                        )
                    }
                    .frame(maxHeight: .infinity)
                    .background(Theme.sharedTheme.primaryUi01)
                }
            } else if searchResults.isShowingPredictiveSearch || (searchResults.isSearchingPredictive && !searchResults.predictive.isEmpty) {
                List {
                    Section(content: {
                        PredictiveList()
                            .onAppear {
                                self.searchAnalyticsHelper.trackPredictiveShown()
                            }
                    }, footer: {
                        showFullResultsButton
                    })
                    .listRowBackground(theme.primaryUi01)
                    .listSectionSeparator(.hidden, edges: .bottom)
                }
                .scrollDismissesKeyboard(.immediately)
                .listStyle(.plain)
                .listRowSeparatorTint(theme.primaryUi05)
                .scrollContentBackground(.hidden)
            } else {
                VStack(spacing: 0) {
                    if searchResults.combinedResults.count > 1 {
                        filterPicker
                    }
                    List {
                        if displayMode != .episodes {
                            localResults
                        }
                        combinedList
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .listStyle(.plain)
                    .listRowSeparatorTint(theme.primaryUi05)
                    .scrollContentBackground(.hidden)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .onAppear() {
                        self.searchAnalyticsHelper.trackListShown(displayMode)
                    }
                }
            }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
    }

    @ViewBuilder var showFullResultsButton: some View {
        Button(action: {
            searchResults.search(term: searchResults.currentSearchTerm)
            searchAnalyticsHelper.trackPredictiveViewAllTapped(term: searchResults.currentPredictiveSearchTerm)
        }, label: {
            Text(L10n.searchResultsViewAll(searchResults.currentSearchTerm))
                .font(style: .subheadline, weight: .medium)
                .foregroundColor(AppTheme.color(for: .primaryInteractive01, theme: theme))
        })
        .background(theme.primaryUi01)
    }

    @ViewBuilder var filterPicker: some View {
        PillSegmentControl(SearchResultsListView.DisplayMode.allCases, selection: $displayMode) { item in
            Text(item.localizedDescription)
        }
        .padding(.bottom, 8)
        .background(theme.secondaryUi01)
        .onChange(of: displayMode) { newValue in
            searchAnalyticsHelper.trackFilterTapped(newValue.analyticsDescription)
        }
    }

    var filteredResults: [CombinedSearchResultType] {
        let podcastsUuids = searchResults.podcasts.map({ result in
            result.uuid
        })
        switch displayMode {
            case .allResults:
                return searchResults.combinedResults.filter { result in
                    switch result {
                        case .podcast(let podcast):
                            return !podcastsUuids.contains(podcast.uuid)
                        default:
                            return true
                    }
                }
            case .episodes:
                return searchResults.combinedResults.filter { result in
                    if case .episode = result {
                        return true
                    } else {
                        return false
                    }
                }
            case .podcasts:
                return searchResults.combinedResults.filter { result in
                    if case let .podcast(podcast) = result {
                        return !podcastsUuids.contains(podcast.uuid)
                    } else {
                        return false
                    }
                }
        }
    }

    @ViewBuilder var combinedList: some View {
        ForEach(filteredResults, id: \.self) { result in
            switch result {
                case .podcast(let podcast):
                    SearchResultCell(episode: nil, result: podcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                        .listRowBackground(theme.primaryUi01)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
                case .episode(let episode):
                    let played = searchResults.playedEpisodesUUIDs.contains(episode.uuid)
                    SearchResultCell(episode: episode, result: nil, played: played, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                        .listRowBackground(theme.primaryUi01)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
            }

        }
    }

    @ViewBuilder var localResults: some View {
        ForEach(searchResults.podcasts, id: \.self) { localPodcast in
            SearchResultCell(episode: nil, result: localPodcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                .listRowBackground(theme.primaryUi01)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
        }
    }

    @ViewBuilder var predictiveList: some View {
        ForEach(searchResults.predictive.prefix(Constants.maxNumberOfEpisodes), id: \.self) { predictiveSearch in
            switch predictiveSearch.type {
                case .term(let searchTerm):
                    termRow(term: searchTerm)
                    .listRowBackground(theme.primaryUi01)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 0
                    }
                case .podcast:
                    SearchResultCell(episode: nil, result: PodcastFolderSearchResult(from: predictiveSearch), played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                        .listRowBackground(theme.primaryUi01)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
                default:
                    EmptyView()
            }
        }
    }

    func highlightTerm(_ term: String, on searchTerm: String) -> AttributedString {
        var result = AttributedString(searchTerm)
        result.foregroundColor = theme.primaryText02
        guard let range = result.range(of: term) else {
            return result
        }
        result[range].foregroundColor = theme.primaryText01

        return result
    }

    @ViewBuilder
    func termRow(term: String) -> some View {
        let formattedText = highlightTerm(searchResults.currentSearchTerm, on: term)
        Button(action: {
            searchResults.search(term: term)
            searchHistory.add(searchTerm: term)
        }, label: {
            HStack(spacing: 0) {
                Image("search")
                    .frame(width: 24, height: 24)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .padding(.trailing, 12)
                Text(formattedText)
                    .font(style: .subheadline, weight: .medium)
                Spacer()
            }
        })
    }

    enum Constants {
        static let maxNumberOfEpisodes = 20
    }
}

struct NewSearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
            .previewWithAllThemes()
    }
}
