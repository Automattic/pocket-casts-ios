import SwiftUI
import PocketCastsDataModel

struct PlaylistsView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel
    @Environment(\.requireAccount) private var requireAccount

    @State private var model: PlaylistsViewModel
    @State private var didTrackShown = false

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
        .task {
            model.load()
        }
        .onChange(of: model.state) { _, newState in
            guard !didTrackShown, newState != .loading else { return }
            didTrackShown = true
            Analytics.track(.filterListShown, properties: ["filter_count": model.playlists.count])
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var playlistsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.tvTabPlaylists)
                        .font(.title2)
                        .foregroundStyle(Color.pcTextPrimary)
                    playlistsCollection
                }
            }
        }
    }

    var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvPlaylistsEmptyTitle)
        } description: {
            Text(L10n.tvPlaylistsEmptySubtitle)
        } actions: {
            Button(L10n.tvPlaylistsEmptyActionTitle) {
                requireAccount { tabRouter.selectedTab = .home }
            }
        }
    }

    private let items: [GridItem] = (0..<3).map { _ in
        GridItem(.flexible(minimum: Layout.gridSize), spacing: 48)
    }

    @Namespace private var listNamespace

    var playlistsCollection: some View {
        LazyVGrid(columns: items, spacing: 48, content: {
            ForEach(model.playlists, id: \.uuid) { playlist in
                NavigationLink(value: playlist) {
                    PlaylistCell(playlist: playlist)
                }
                .buttonStyle(.card)
                .prefersDefaultFocus(playlist.id == model.playlists.first?.id, in: listNamespace)
            }
        })
        .focusScope(listNamespace)
        .navigationDestination(for: EpisodeFilter.self) { playlist in
            PlaylistDetailView(model: PlaylistDetailsViewModel(playlist: playlist))
        }
    }
}

#Preview {
    PlaylistsView(model: PlaylistsViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
