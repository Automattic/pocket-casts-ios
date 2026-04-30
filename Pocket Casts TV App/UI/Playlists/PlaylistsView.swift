import SwiftUI
import Combine

@Observable
class PlaylistsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var playlists: [MockPlaylist] = MockData.makePlaylists()

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}

struct PlaylistsView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = PlaylistsViewModel()

    enum Layout {
        static let gridSize = CGFloat(496)
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
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var playlistsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.playlists)
                        .font(.title)
                        .foregroundStyle(Color.textPrimary)
                    playlistsCollection
                }
            }
        }
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvPlaylistsEmptyTitle, subtitle: L10n.tvPlaylistsEmptySubtitle, actionTitle: L10n.tvPlaylistsEmptyActionTitle) {
            tabRouter.selectedTab = .home
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
            }
        })
        .focusScope(listNamespace)
        .navigationDestination(for: MockPlaylist.self) { playlist in

        }
    }
}

#Preview {
    PlaylistsView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
