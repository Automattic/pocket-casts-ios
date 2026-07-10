import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct PredictiveList: View {

    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    var termsResults: [PredictiveSearchResult] {
        searchResults.predictive.filter { result in
            if case .term = result.type {
                return true
            }
            return false
        }
    }

    var nonTermsResults: [PredictiveSearchResult] {
        let podcastsUuids = searchResults.podcasts.map({ result in
            result.uuid
        })
        return searchResults.predictive.filter { result in
            switch result.type {
                case .podcast(let podcast):
                    return !podcastsUuids.contains { uuid in
                        uuid == podcast.uuid
                    }
                default:
                    return false
            }
        }
    }

    var body: some View {
        ForEach(termsResults, id: \.self) { predictiveSearch in
            predictiveRow(for: predictiveSearch)
        }
        ForEach(searchResults.podcasts, id: \.self) { localPodcast in
            SearchResultCell(episode: nil, result: localPodcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                .listRowBackground(theme.searchBackground)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
        }
        ForEach(nonTermsResults, id: \.self) { predictiveSearch in
            predictiveRow(for: predictiveSearch)
        }
    }

    @ViewBuilder
    func predictiveRow(for predictiveSearch: PredictiveSearchResult) -> some View {
        switch predictiveSearch.type {
            case .term(let searchTerm):
                termRow(term: searchTerm)
                    .listRowBackground(theme.searchBackground)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 0
                    }
                    .background(theme.searchBackground)
            case .podcast:
                SearchResultCell(episode: nil, result: PodcastFolderSearchResult(from: predictiveSearch), played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .searchBackground))
                    .listRowBackground(theme.searchBackground)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 0
                    }
            default:
                EmptyView()
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
        let formattedText = highlightTerm(searchResults.currentPredictiveSearchTerm, on: term)
        Button(action: {
            searchAnalyticsHelper.trackPredictiveTermTapped(term: term)
            searchResults.search(term: term)
            searchHistory.add(searchTerm: term)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastSearchRequest, object: term)
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
            .background(theme.searchBackground)
        })
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
