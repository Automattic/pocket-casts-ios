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
            SearchResultCell(episode: nil, result: localPodcast, played: false, showDivider: !FeatureFlag.searchImprovements.enabled, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                .listRowBackground(theme.primaryUi01)
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
                VStack {
                    termRow(term: searchTerm)
                    if !FeatureFlag.searchImprovements.enabled {
                        ThemedDivider()
                    }
                }
                .if(!FeatureFlag.searchImprovements.enabled) { content in
                    content.padding(EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 8))
                }
                .listRowBackground(theme.primaryUi01)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
                .background(theme.primaryUi01)
            case .podcast:
                SearchResultCell(episode: nil, result: PodcastFolderSearchResult(from: predictiveSearch), played: false, showDivider: !FeatureFlag.searchImprovements.enabled, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                    .listRowBackground(theme.primaryUi01)
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
            .background(theme.primaryUi01)
        })
    }

}
