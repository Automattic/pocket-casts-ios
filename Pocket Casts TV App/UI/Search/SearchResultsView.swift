import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

fileprivate enum Layout {
    static let cellSize = CGFloat(250)
}

/// `FocusStore` identities for the search sections, so a `RowSection` title highlights
/// while anything inside it holds focus.
enum SearchFocusSection {
    static let featured = "search_featured"
    static let episodes = "search_episodes"
    static let podcasts = "search_podcasts"
}

struct SearchResultsView<ViewModel: SearchableViewModel>: View {

    @Environment(MainTabViewModel.self) var mainTabModel: MainTabViewModel

    @Bindable var model: ViewModel

    @State private var showNowPlayingPlayer = false

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.cellSize), spacing: 48)
    }

    private let episodeItems: [GridItem] = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]

    var body: some View {
        Group {
            switch model.state {
            case .searching:
                ProgressView(L10n.tvSearchSearching)
            case .empty:
                ContentUnavailableView.search(text: model.searchTerm)
            case .results:
                switch model.scope {
                case .topResults:
                    if model.podcastResults.isEmpty, model.episodeResults.isEmpty {
                        ContentUnavailableView.search(text: model.searchTerm)
                    } else {
                        SearchTopResultsView(model: model)
                    }
                case .podcasts:
                    if model.podcastResults.isEmpty {
                        ContentUnavailableView.search(text: model.searchTerm)
                    } else {
                        results
                    }
                case .episodes:
                    if model.episodeResults.isEmpty {
                        ContentUnavailableView.search(text: model.searchTerm)
                    } else {
                        episodeResults
                    }
                }
            case .error(let error):
                Text(L10n.tvSearchFailed(error.localizedDescription))
                    .font(.headline)
                    .foregroundStyle(Color.pcTextSecondary)
            case .query:
                DiscoverAllView(model: mainTabModel.discoverAllViewModel, source: DiscoverAnalytics.searchSource)
            }
        }
        .navigationDestination(for: DiscoverPodcast.self) { podcast in
            if let uuid = podcast.uuid {
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid, isDiscover: true))
            }
        }
        .navigationDestination(for: DiscoverCategory.self) { discoverCategory in
            DiscoverPodcastsListView(category: discoverCategory, source: DiscoverAnalytics.searchSource)
        }
        .navigationDestination(for: PodcastFolderSearchResult.self) { podcast in
            PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast.uuid))
        }
        .animation(.easeInOut, value: model.state)
        .animation(.easeInOut, value: model.scope)
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    var results: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(model.podcastResults, id: \.self) { result in
                    switch result {
                    case .podcast(let podcast):
                        NavigationLink(value: podcast) {
                            PodcastImage(uuid: podcast.uuid, size: .page)
                                .frame(width: Layout.cellSize, height: Layout.cellSize)
                        }
                        .buttonStyle(.card)
                        .accessibilityLabel(podcast.title ?? "")
                        .simultaneousGesture(TapGesture().onEnded {
                            SearchAnalytics.podcastTapped(podcast)
                        })
                    case .episode:
                        EmptyView()
                    }
                }
            })
        }
    }

    /// Without video results this is the plain grid it has always been. With them, the
    /// video episodes lead in a `Featured` row and the grid drops below an `Episodes`
    /// heading, holding whatever the row didn't already show.
    @ViewBuilder
    var episodeResults: some View {
        if model.videoEpisodeResults.isEmpty {
            ScrollView {
                episodeGrid(model.episodeResults)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: RowSectionLayout.sectionSpacing) {
                    SearchFeaturedEpisodesRow(episodes: model.videoEpisodeResults)
                    if !model.remainingEpisodeResults.isEmpty {
                        RowSection(title: L10n.episodes, focusSection: SearchFocusSection.episodes) {
                            episodeGrid(model.remainingEpisodeResults)
                        }
                    }
                }
            }
        }
    }

    private func episodeGrid(_ episodes: [EpisodeSearchResult]) -> some View {
        LazyVGrid(columns: episodeItems, spacing: 24, content: {
            ForEach(episodes, id: \.self) { episode in
                Button() {
                    SearchAnalytics.episodeTapped(episode)
                    Task {
                        let playSuccess = await model.playEpisode(episode)
                        await MainActor.run {
                            if playSuccess {
                                showNowPlayingPlayer = true
                            } else {
                                ToastManager.shared.show(L10n.playbackFailed)
                            }
                        }
                    }
                } label: {
                    SearchEpisodeRow(model: episode)
                }
                .buttonStyle(.card)
                .setFocus(section: SearchFocusSection.episodes)
                .discoveryEpisodeContextMenu(podcastUuid: episode.podcastUuid, episodeUuid: episode.uuid)
            }
        })
    }
}
