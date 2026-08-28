import SwiftUI
import PocketCastsServer

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel

    @State var displayMode: SearchDisplayMode = .allResults

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
                .background(Theme.sharedTheme.searchBackground)
            } else if searchResults.isSearchingForPodcasts || (searchResults.isSearchingPredictive && searchResults.predictive.isEmpty) {
                  ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(AppTheme.loadingActivityColor().color)
            } else if searchResults.noResults {
                if searchResults.isShowingPredictiveSearch {
                    VStack {
                        Spacer()
                    }
                    .background(Theme.sharedTheme.searchBackground)
                } else {
                    HStack(alignment: .center) {
                        EmptyStateView(title: L10n.searchResultsEmptyTitle,
                                       message: L10n.searchResultsEmptyMessage,
                                       icon: { Image("search") },
                                       actions: []
                        )
                    }
                    .frame(maxHeight: .infinity)
                    .background(Theme.sharedTheme.searchBackground)
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
                    .listRowBackground(theme.searchBackground)
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
                        if activeDisplayMode == .allResults || activeDisplayMode == .podcasts {
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
                        self.searchAnalyticsHelper.trackListShown(activeDisplayMode)
                    }
                }
            }
        }
        .background(theme.searchBackground.ignoresSafeArea())
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
        .background(theme.searchBackground)
    }

    /// The filters offered for the current results: Networks only joins them when there are any.
    var availableFilters: [SearchDisplayMode] {
        var filters: [SearchDisplayMode] = [.allResults, .podcasts, .episodes]
        if !searchResults.networks.isEmpty {
            filters.append(.networks)
        }
        return filters
    }

    /// The filter in effect, which falls back to Top Results when the selected one is no longer
    /// offered — searching again can leave Networks selected with no networks to show.
    var activeDisplayMode: SearchDisplayMode {
        availableFilters.contains(displayMode) ? displayMode : .allResults
    }

    @ViewBuilder var filterPicker: some View {
        PillSegmentControl(availableFilters, selection: Binding(get: { activeDisplayMode }, set: { displayMode = $0 })) { item in
            Text(item.localizedDescription)
        }
        .padding(.bottom, 8)
        .background(LiquidGlass.isEnabled ? theme.searchBackground : theme.secondaryUi01)
        .onChange(of: displayMode) { _, newValue in
            searchAnalyticsHelper.trackFilterTapped(newValue.analyticsDescription)
        }
    }

    var filteredResults: [CombinedSearchResultType] {
        let podcastsUuids = searchResults.podcasts.map({ result in
            result.uuid
        })
        switch activeDisplayMode {
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
            case .networks:
                return searchResults.combinedResults.filter { result in
                    if case .network = result {
                        return true
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
                    SearchResultCell(episode: nil, result: podcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                        .listRowBackground(theme.searchBackground)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
                case .episode(let episode):
                    SearchResultCell(episode: episode, result: nil, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                        .listRowBackground(theme.searchBackground)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
                case .network(let network):
                    NetworkSearchResultCell(network: network, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                        .listRowBackground(theme.searchBackground)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 0
                        }
            }
        }
    }

    @ViewBuilder var localResults: some View {
        ForEach(searchResults.podcasts, id: \.self) { localPodcast in
            SearchResultCell(episode: nil, result: localPodcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                .listRowBackground(theme.searchBackground)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
        }
    }
}

/// Under Liquid Glass, search uses the standard list background to match other list
/// screens; the legacy appearance keeps the original `primaryUi01`.
private extension ThemeStyle {
    static var searchBackground: ThemeStyle {
        LiquidGlass.isEnabled ? .primaryUi02 : .primaryUi01
    }
}

private extension Theme {
    var searchBackground: Color {
        AppTheme.color(for: .searchBackground, theme: self)
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
            .previewWithAllThemes()
    }
}

#if DEBUG

/// Results carrying networks, which is what puts the Networks filter on the pill row.
#Preview("Results with networks") {
    let searchResults = SearchResultsModel()
    searchResults.combinedResults = NetworkSearchPreviewData.networks.map { .network($0) }

    return SearchResultsView()
        .setupDefaultEnvironment()
        .environmentObject(searchResults)
        .environmentObject(SearchAnalyticsHelper(source: .discover))
        .environmentObject(NetworkNavigator(source: .discover))
        .environmentObject(SearchHistoryModel.shared)
}

#endif
