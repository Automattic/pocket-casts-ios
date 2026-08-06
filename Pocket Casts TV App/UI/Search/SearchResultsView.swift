import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

fileprivate enum Layout {
    static let cellSize = CGFloat(250)
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
                DiscoverAllView(model: mainTabModel.discoverAllViewModel)
            }
        }
        .navigationDestination(for: DiscoverPodcast.self) { podcast in
            if let uuid = podcast.uuid {
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid, isDiscover: true))
            }
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
                            Analytics.track(.searchResultTapped, properties: [
                                "source": "search",
                                "uuid": podcast.uuid,
                                "result_type": podcast.isLocal == true ? "podcast_local_result" : "podcast_remote_result"
                            ])
                        })
                    case .episode:
                        EmptyView()
                    }
                }
            })
            .navigationDestination(for: PodcastFolderSearchResult.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast.uuid))
            }
        }
    }

    var episodeResults: some View {
        ScrollView {
            LazyVGrid(columns: episodeItems, spacing: 24, content: {
                ForEach(model.episodeResults, id: \.self) { episode in
                    Button() {
                        Analytics.track(.searchResultTapped, properties: [
                            "source": "search",
                            "uuid": episode.uuid,
                            "result_type": "episode"
                        ])
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
                    .discoveryEpisodeContextMenu(podcastUuid: episode.podcastUuid, episodeUuid: episode.uuid)
                }
            })
        }
    }
}
