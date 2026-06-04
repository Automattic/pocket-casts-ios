import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

fileprivate enum Layout {
    static let cellSize = CGFloat(250)
}

struct SearchResultsView<ViewModel: SearchableViewModel>: View {

    @Bindable var model: ViewModel

    let dataManager: TVDataManager = TVDataManager.shared
    
    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.cellSize), spacing: 48)
    }

    private let episodeItems: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        switch model.state {
        case .searching:
            ProgressView(L10n.tvSearchSearching)
        case .empty:
            ContentUnavailableView.search(text: model.searchTerm)
        case .results:
            switch model.scope {
            case .podcasts:
                results
            case .episodes:
                episodeResults
            }
        case .error(let error):
            Text(L10n.tvSearchFailed(error.localizedDescription))
                .font(.headline)
                .foregroundStyle(Color.pcTextSecondary)
        case .query:
            Text(L10n.tvSearchTypeSomething)
                .font(.headline)
                .foregroundStyle(Color.pcTextSecondary)
        }
    }

    var results: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(model.results, id: \.self) { result in
                    switch result {
                    case .podcast(let podcast):
                        NavigationLink(value: podcast) {
                            PodcastImage(uuid: podcast.uuid, size: .page)
                                .frame(width: Layout.cellSize, height: Layout.cellSize)
                        }
                        .buttonStyle(.card)
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
            LazyVGrid(columns: episodeItems, spacing: 64, content: {
                ForEach(model.episodeResults, id: \.self) { result in
                    switch result {
                    case .podcast:
                        EmptyView()
                    case .episode(let episode):
                        Button() {
                            Task {
                                await dataManager.playEpisode(episode)
                            }
                        } label: {
                            SearchEpisodeRow(model: episode)
                        }
                        .buttonStyle(.card)
                    }
                }
            })
            .navigationDestination(for: PodcastFolderSearchResult.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast.uuid))
            }
        }
    }
}
