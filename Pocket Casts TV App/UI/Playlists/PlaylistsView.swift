import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct PlaylistsView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel
    @Environment(\.requireAccount) private var requireAccount

    @State private var model: PlaylistsViewModel
    @State private var showDownloadModal = false

    enum Layout {
        static let gridSize = CGFloat(496)
    }

    init(model: PlaylistsViewModel) {
        _model = State(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                playlistsView
            case .empty:
                emptyView
            }
        }
        .animation(.easeInOut, value: model.state)
        .sheet(isPresented: $showDownloadModal) {
            DownloadAppModal()
        }
        .task {
            await model.load()
            Analytics.track(.filterListShown, properties: ["filter_count": model.playlists.count])
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    @State private var path = StackPath()
    var playlistsView: some View {
        NavigationStack(path: $path.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.tvTabPlaylists)
                        .font(.title2)
                        .foregroundStyle(Color.pcTextPrimary)
                    playlistsCollection
                }
            }
            .navigationDestination(for: DiscoverPodcast.self) { podcast in
                if let uuid = podcast.uuid {
                    PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid))
                }
            }
        }
        .syncNavigationDetail(path: path.navigationPath, tabRouter: tabRouter)
        .environment(path)
    }

    var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvPlaylistsEmptyTitle)
        } description: {
            Text(L10n.tvPlaylistsEmptySubtitle)
        } actions: {
            Button(L10n.tvPlaylistsEmptyActionTitle) {
                Analytics.track(.filterCreateButtonTapped)
                showDownloadModal = true
            }
        }
    }

    private let items: [GridItem] = (0..<3).map { _ in
        GridItem(.flexible(minimum: Layout.gridSize), spacing: 48)
    }

    @Namespace private var listNamespace

    var playlistsCollection: some View {
        LazyVGrid(columns: items, spacing: 48, content: {
            ForEach(model.playlists) { playlist in
                NavigationLink(value: playlist) {
                    PlaylistCell(playlist: playlist)
                }
                .buttonStyle(.card)
                .prefersDefaultFocus(playlist.id == model.playlists.first?.id, in: listNamespace)
            }
        })
        .focusScope(listNamespace)
        .navigationDestination(for: PlaylistItem.self) { playlist in
            PlaylistDetailView(model: PlaylistDetailsViewModel(playlist: playlist, detail: true))
        }
    }
}

#Preview {
    PlaylistsView(model: PlaylistsViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
