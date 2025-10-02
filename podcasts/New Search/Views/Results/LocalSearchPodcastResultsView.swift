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
        ZStack {
            if listMode == .library {
                defaultLibraryList
            }

            if listMode == .folder {
                folderPodcastList
            }

            if listMode == .search {
                searchResultsList
            }
        }
    }

    @ViewBuilder
    private var defaultLibraryList: some View {
        let entries = defaultLibraryItems

        if entries.isEmpty {
            podcastEmptyState
        } else {
            List {
                listHeader
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, result in
                    SearchResultCell(
                        episode: nil,
                        result: result,
                        played: false,
                        showDivider: index < entries.count - 1,
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
    }

    @ViewBuilder
    private var folderPodcastList: some View {
        if folderResults.isEmpty {
            podcastEmptyState
        } else {
            List {
                listHeader
                ForEach(Array(folderResults.enumerated()), id: \.element.id) { index, result in
                    SearchResultCell(
                        episode: nil,
                        result: result,
                        played: false,
                        showDivider: index < folderResults.count - 1,
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
    }

    @ViewBuilder
    private var searchResultsList: some View {
        let podcasts = searchResults
        if podcasts.isEmpty {
            podcastEmptyState
        } else {
            List {
                listHeader
                ForEach(Array(podcasts.enumerated()), id: \.element.id) { index, podcastResult in
                    SearchResultCell(
                        episode: nil,
                        result: podcastResult,
                        played: false,
                        showDivider: index < podcasts.count - 1,
                        showPodcastSubscribeButton: false,
                        cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01),
                        action: {
                        onSelectResult(podcastResult)
                    })
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
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

    private var podcastEmptyState: some View {
        VStack(spacing: 12) {
            if listMode == .folder {
                if hasAnyPodcastsInFolder {
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
            } else {
                let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
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
}
