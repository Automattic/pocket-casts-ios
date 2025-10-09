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
    @State private var navigationPath: [LocalSearchRoute] = []
    @State private var previousNavigationPath: [LocalSearchRoute] = []

    private let dismissAction: (() -> Void)?

    init(playlist: EpisodeFilter, dismissAction: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: LocalSearchViewModel(playlist: playlist))
        self.dismissAction = dismissAction
    }

    var body: some View {
        navigationContent
            .background(backgroundColor.ignoresSafeArea())
            .safeAreaInset(edge: .top) {
                searchBar
                    .background(theme.secondaryUi01)
            }
            .onAppear {
                viewModel.onAppear(searchResultsModel: searchResults)
                previousNavigationPath = navigationPath
            }
            .onDisappear { viewModel.onDisappear() }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if navigationPath.isEmpty {
                        closeButton
                    } else {
                        backButton
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .modify({ view in
                if #available(iOS 17.1, *) {
                    view
                        .toolbarRole(.navigationStack)
                } else {
                    view
                }
            })
            .onChange(of: navigationPath) { newValue in
                handleNavigationPathChange(newValue, previousPath: previousNavigationPath)
                previousNavigationPath = newValue
            }
    }

    private var navigationContent: some View {
        NavigationStack(path: $navigationPath) {
            podcastsView
                .navigationDestination(for: LocalSearchRoute.self) { route in
                    destinationView(for: route)
                }
        }
    }

    private func handleSelection(for result: PodcastFolderSearchResult) {
        switch result.kind {
        case .folder:
            viewModel.selectFolder(result)
            let route = LocalSearchRoute.folder(result.uuid)
            if navigationPath.last != route {
                withAnimation(navigationAnimation) {
                    navigationPath.append(route)
                }
            }
        case .podcast:
            if navigationPath.last?.isPodcast == true {
                withAnimation(navigationAnimation) {
                    navigationPath.removeLast()
                }
            }
            guard let podcast = viewModel.podcast(from: result) else { return }
            viewModel.beginEpisodeMode(with: podcast)
            let route = LocalSearchRoute.podcast(podcast.uuid)
            if navigationPath.last != route {
                withAnimation(navigationAnimation) {
                    navigationPath.append(route)
                }
            }
        @unknown default:
            break
        }
    }

    private var navigationAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.3)
    }

    private var episodeRemovalAnimation: Animation {
        .easeInOut(duration: 0.25)
    }
}

enum PodcastListMode {
    case library, folder, search
}

private extension LocalSearchView {
    private var backgroundColor: Color {
        AppTheme.color(for: .primaryUi02, theme: theme)
    }

    private var podcastsView: some View {
        LocalSearchPodcastResultsView(
            listMode: viewModel.rootListMode,
            selectedFolder: nil,
            searchText: viewModel.searchText,
            defaultLibraryItems: viewModel.defaultLibraryItems,
            folderResults: viewModel.filteredFolderPodcastResults,
            hasAnyPodcastsInFolder: viewModel.hasAnyPodcastsInFolder,
            searchResults: viewModel.searchResultsPodcasts,
            onSelectResult: { handleSelection(for: $0) },
            disableLibraryAnimation: viewModel.disableLibraryAnimation
        )
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchPromptString: String {
        switch viewModel.searchMode {
        case .podcasts:
            return L10n.searchPodcasts
        case .episodes:
            return L10n.localizedFormat("user_episodes_search_episodes_prompt", "Localizable", "Search Episodes")
        }
    }

    private var searchBar: some View {
        SearchField(
            theme: LocalSearchFieldTheme(),
            text: $viewModel.searchText,
            showsCancelButton: false,
            placeholder: searchPromptString
        )
        .submitLabel(.search)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .onSubmit {
            viewModel.triggerImmediateSearch()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var closeButton: some View {
        Button {
            closeModal()
        } label: {
            Image("close")
                .renderingMode(.template)
                .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
        }
        .accessibilityLabel(L10n.close)
    }

    private var backButton: some View {
        Button {
            popNavigation()
        } label: {
            Image("nav-back")
        }
        .foregroundColor(AppTheme.color(for: .primaryIcon02, theme: theme))
        .accessibilityLabel(L10n.back)
    }

    private var doneButton: some View {
        Button {
            closeModal()
        } label: {
            Text(L10n.done)
        }
        .fontWeight(.semibold)
        .foregroundColor(AppTheme.color(for: .secondaryIcon01, theme: theme))
    }

    @ViewBuilder
    private func destinationView(for route: LocalSearchRoute) -> some View {
        switch route {
        case .folder:
            LocalSearchPodcastResultsView(
                listMode: .folder,
                selectedFolder: viewModel.selectedFolder,
                searchText: viewModel.searchText,
                defaultLibraryItems: viewModel.defaultLibraryItems,
                folderResults: viewModel.filteredFolderPodcastResults,
                hasAnyPodcastsInFolder: viewModel.hasAnyPodcastsInFolder,
                searchResults: viewModel.searchResultsPodcasts,
                onSelectResult: { handleSelection(for: $0) },
                disableLibraryAnimation: viewModel.disableLibraryAnimation
            )
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        case .podcast:
            LocalSearchEpisodeResultsView(
                isLoading: viewModel.isEpisodeSearchInFlight,
                episodes: viewModel.episodes,
                searchText: viewModel.searchText,
                selectedPodcastTitle: viewModel.selectedPodcast?.title,
                onAddEpisode: { result in
                    if reduceMotion {
                        viewModel.handleAddEpisode(result)
                    } else {
                        withAnimation(episodeRemovalAnimation) {
                            viewModel.handleAddEpisode(result)
                        }
                    }
                }
            )
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func closeModal() {
        if let dismissAction {
            dismissAction()
        } else {
            dismiss()
        }
    }

    func handleNavigationPathChange(_ newPath: [LocalSearchRoute], previousPath: [LocalSearchRoute]) {
        let previousPodcastCount = previousPath.filter(\.isPodcast).count
        let newPodcastCount = newPath.filter(\.isPodcast).count
        if newPodcastCount < previousPodcastCount {
            viewModel.clearSelectedPodcast()
        }

        let previousFolderCount = previousPath.filter(\.isFolder).count
        let newFolderCount = newPath.filter(\.isFolder).count
        if newFolderCount < previousFolderCount {
            viewModel.clearSelectedFolder()
        }
    }

    func popNavigation() {
        guard !navigationPath.isEmpty else { return }
        withAnimation(navigationAnimation) {
            navigationPath.removeLast()
        }
    }
}

private enum LocalSearchRoute: Hashable {
    case folder(String)
    case podcast(String)

    var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }

    var isPodcast: Bool {
        if case .podcast = self { return true }
        return false
    }
}

private final class LocalSearchFieldTheme: SearchField.SearchTheme {
    override var background: Color { theme.primaryField01 }
    override var placeholder: Color { theme.primaryText02 }
    override var text: Color { theme.primaryText02 }
    override var cancel: Color { theme.primaryText01 }
    override var icon: Color { theme.primaryIcon02 }
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
