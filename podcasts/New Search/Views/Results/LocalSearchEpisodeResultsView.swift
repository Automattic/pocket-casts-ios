import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct LocalSearchEpisodeResultsView: View {
    @EnvironmentObject private var theme: Theme

    let isLoading: Bool
    let episodes: [EpisodeSearchResult]
    let searchText: String
    let selectedPodcastTitle: String?
    let onAddEpisode: (EpisodeSearchResult) -> Void

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(AppTheme.loadingActivityColor().color)
        } else if episodes.isEmpty {
            episodesEmptyState
        } else {
            List {
                ForEach(Array(episodes.enumerated()), id: \.element) { index, searchResult in
                    SearchResultCell(
                        episode: searchResult,
                        result: nil,
                        played: false,
                        showDivider: index < episodes.count - 1,
                        showEpisodeAddButton: true,
                        cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01)) {
                            onAddEpisode(searchResult)
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
                Text(selectedPodcastTitle ?? L10n.search)
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
}
