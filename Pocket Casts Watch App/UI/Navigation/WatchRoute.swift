import SwiftUI

/// A screen that can be pushed onto the watch app's navigation stack.
enum WatchRoute: Hashable {
    case source(Source)
    case interface(WatchInterfaceType)

    /// Returns `nil` for interface types that have no screen of their own.
    init?(_ interface: WatchInterfaceType) {
        switch interface {
        case .unknown, .interface, .filter:
            return nil
        default:
            self = .interface(interface)
        }
    }
}

/// Resolves a route to the screen it pushes. Registered once on the root stack so that
/// any screen can push any route.
struct WatchRouteView: View {
    let route: WatchRoute

    var body: some View {
        switch route {
        case .source(let source):
            InterfaceView(source: source)
        case .interface(let interface):
            interfaceView(for: interface)
        }
    }

    @ViewBuilder
    private func interfaceView(for interface: WatchInterfaceType) -> some View {
        switch interface {
        case .downloads:
            DownloadListView()
        case .podcasts:
            PodcastsListView()
        case .files:
            FilesListView()
        case .upnext:
            UpNextView()
        case .filterList:
            PlaylistsListView()
        case .nowPlaying:
            NowPlayingContainerView()
        case .effects:
            EffectsView()
        case .episodeDetails:
            if let episode = PlaySourceHelper.playSourceViewModel.nowPlayingEpisode {
                EpisodeView(viewModel: EpisodeDetailsViewModel(episode: episode, playlist: nil), listTitle: L10n.nowPlaying)
            }
        case .unknown, .interface, .filter:
            EmptyView()
        }
    }
}
