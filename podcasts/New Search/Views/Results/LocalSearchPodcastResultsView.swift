import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct LocalSearchPodcastResultsView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let listMode: PodcastListMode
    let selectedFolder: Folder?
    let searchText: String
    let defaultLibraryItems: [PodcastFolderSearchResult]
    let folderResults: [PodcastFolderSearchResult]
    let hasAnyPodcastsInFolder: Bool
    let searchResults: [PodcastFolderSearchResult]
    let onSelectResult: (PodcastFolderSearchResult) -> Void
    let disableLibraryAnimation: Bool

    var body: some View {
        Group {
            if currentResults.isEmpty {
                emptyStateView
            } else {
                resultsList
            }
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        List {
            listHeader
            ForEach(Array(currentResults.enumerated()), id: \.element.id) { index, result in
                SearchResultCell(
                    episode: nil,
                    result: result,
                    played: false,
                    showDivider: index < currentResults.count - 1,
                    showPodcastSubscribeButton: false,
                    cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01),
                    action: {
                    onSelectResult(result)
                })
                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var listHeader: some View {
        if listMode == .library {
            Text(L10n.localizedFormat("user_episodes_search_podcasts_title", "Localizable", "Your Podcasts"))
                .font(style: .headline, weight: .semibold)
                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            switch emptyStateContent {
            case .folder(let hasAnyPodcasts):
                if hasAnyPodcasts {
                    EmptyStateView(
                        title: L10n.discoverNoPodcastsFound,
                        message: L10n.discoverNoPodcastsFoundMsg,
                        icon: { Image(systemName: "info.circle") }
                    )
                } else {
                    EmptyStateView(
                        title: L10n.folderEmptyTitle,
                        message: L10n.folderEmptyDescription,
                        icon: { Image(systemName: "folder") }
                    )
                }
            case .search(let trimmedSearch):
                if trimmedSearch.isEmpty {
                    Text(L10n.localizedFormat("user_episodes_search_podcasts_title", "Localizable", "Your Podcasts"))
                        .font(style: .title3, weight: .semibold)
                        .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    Text(L10n.listeningHistorySearchNoEpisodesText)
                        .multilineTextAlignment(.center)
                        .font(style: .body)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        .padding(.horizontal, 32)
                } else {
                    EmptyStateView(
                        title: L10n.discoverNoPodcastsFound,
                        message: L10n.discoverNoPodcastsFoundMsg,
                        icon: { Image(systemName: "info.circle") }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 48)
    }

    private var navigationAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.3)
    }

    private var currentResults: [PodcastFolderSearchResult] {
        switch listMode {
        case .library:
            return defaultLibraryItems
        case .folder:
            return folderResults
        case .search:
            return searchResults
        }
    }

    private var emptyStateContent: EmptyStateContent {
        switch listMode {
        case .folder:
            return .folder(hasAnyPodcastsInFolder)
        case .library, .search:
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return .search(trimmed)
        }
    }

    private enum EmptyStateContent {
        case folder(Bool)
        case search(String)
    }
}
