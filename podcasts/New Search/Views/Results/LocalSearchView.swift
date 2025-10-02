import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct LocalSearchView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchResults: SearchResultsModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var viewModel: LocalSearchViewModel

    private let dismissAction: (() -> Void)?

    init(playlist: EpisodeFilter, dismissAction: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: LocalSearchViewModel(playlist: playlist))
        self.dismissAction = dismissAction
    }

    var body: some View {
        content
            .background(AppTheme.color(for: .primaryUi02, theme: theme).ignoresSafeArea())
            .onAppear {
                viewModel.onAppear(searchResultsModel: searchResults)
            }
            .onDisappear { viewModel.onDisappear() }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: searchPrompt
            )
            .onSubmit(of: .search) {
                viewModel.triggerImmediateSearch()
            }
            .toolbar {
                LocalSearchToolbar(
                    viewModel: viewModel,
                    iconColor: ThemeColor.secondaryIcon01(for: theme.activeTheme).color,
                    navigationAnimation: navigationAnimation,
                    onClose: closeModal
                )
            }
            .navigationTitle(viewModel.navigationTitle)
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
        switch viewModel.searchMode {
        case .podcasts:
            return Text(L10n.searchPodcasts)
        case .episodes:
            return Text(L10n.localizedFormat("user_episodes_search_episodes_prompt", "Localizable", "Search Episodes"))
        }
    }

    private var content: some View {
        ZStack {
            if viewModel.searchMode == .podcasts {
                LocalSearchPodcastResultsView(
                    listMode: viewModel.podcastListMode,
                    selectedFolder: viewModel.selectedFolder,
                    searchText: viewModel.searchText,
                    defaultLibraryItems: viewModel.defaultLibraryItems,
                    folderResults: viewModel.filteredFolderPodcastResults,
                    hasAnyPodcastsInFolder: viewModel.hasAnyPodcastsInFolder,
                    searchResults: viewModel.searchResultsPodcasts,
                    onSelectResult: { handleSelection(for: $0) },
                    disableLibraryAnimation: viewModel.disableLibraryAnimation
                )
                .id("podcasts")
                .transition(podcastTransition)
            }

            if viewModel.searchMode == .episodes {
                LocalSearchEpisodeResultsView(
                    isLoading: viewModel.isEpisodeSearchInFlight,
                    episodes: viewModel.episodes,
                    searchText: viewModel.searchText,
                    selectedPodcastTitle: viewModel.selectedPodcast?.title,
                    onAddEpisode: { result in
                        withAnimation(navigationAnimation) {
                            viewModel.handleAddEpisode(result)
                        }
                    }
                )
                .id("episodes")
                .transition(episodeTransition)
            }
        }
        .animation(navigationAnimation, value: viewModel.searchMode)
    }

    private func handleSelection(for result: PodcastFolderSearchResult) {
        if result.kind == .folder {
            viewModel.selectFolder(result)
        } else {
            guard let podcast = viewModel.podcast(from: result) else { return }
            withAnimation(navigationAnimation) {
                viewModel.beginEpisodeMode(with: podcast)
            }
            viewModel.finalizeEpisodeModeTransition()
        }
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
}

enum PodcastListMode {
    case library, folder, search
}

private extension LocalSearchView {
    func closeModal() {
        if let dismissAction {
            dismissAction()
        } else {
            dismiss()
        }
    }
}

private struct LocalSearchToolbar: ToolbarContent {
    @ObservedObject var viewModel: LocalSearchViewModel
    let iconColor: Color
    let navigationAnimation: Animation
    let onClose: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if viewModel.selectedPodcast != nil {
                Button {
                    withAnimation(navigationAnimation) {
                        viewModel.clearSelectedPodcast()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(iconColor)
                .accessibilityLabel(L10n.back)
            } else if viewModel.selectedFolder != nil {
                Button {
                    withAnimation(navigationAnimation) {
                        viewModel.clearSelectedFolder()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(iconColor)
                .accessibilityLabel(L10n.back)
            } else {
                Button {
                    onClose()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(iconColor)
                }
                .accessibilityLabel(L10n.close)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                onClose()
            } label: {
                Text(L10n.done)
            }
            .foregroundColor(iconColor)
        }
    }
}

struct LocalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocalSearchView(playlist: EpisodeFilter())
            .environmentObject(SearchAnalyticsHelper(source: .unknown))
            .environmentObject(SearchResultsModel())
            .environmentObject(SearchHistoryModel(userDefaults: UserDefaults(suiteName: "LocalSearchViewPreview") ?? .standard))
            .previewWithAllThemes()
    }
}
