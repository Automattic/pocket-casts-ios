import Foundation
import PocketCastsUtils

// MARK: - YouTubePlaylistListViewModel

@MainActor
final class YouTubePlaylistListViewModel: ObservableObject {

    // MARK: - State

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)

        static func == (lhs: LoadState, rhs: LoadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    @Published var playlists: [YouTubeUserPlaylist] = []
    @Published var loadState: LoadState = .idle

    private let client: any YouTubePlaylistAPIClientProtocol

    init(client: any YouTubePlaylistAPIClientProtocol = YouTubePlaylistAPIClient.shared) {
        self.client = client
    }

    // MARK: - Actions

    func loadPlaylists() {
        guard loadState != .loading else { return }
        loadState = .loading

        Task {
            do {
                let results = try await client.fetchMyPlaylists()
                playlists = results
                loadState = .loaded
            } catch {
                loadState = .error(error.localizedDescription)
            }
        }
    }

    func reload() {
        playlists = []
        loadState = .idle
        loadPlaylists()
    }
}

// MARK: - YouTubePlaylistDetailViewModel

@MainActor
final class YouTubePlaylistDetailViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)

        static func == (lhs: LoadState, rhs: LoadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    let playlist: YouTubeUserPlaylist

    @Published var items: [YouTubePlaylistVideo] = []
    @Published var loadState: LoadState = .idle

    private let client: any YouTubePlaylistAPIClientProtocol

    init(playlist: YouTubeUserPlaylist, client: any YouTubePlaylistAPIClientProtocol = YouTubePlaylistAPIClient.shared) {
        self.playlist = playlist
        self.client = client
    }

    // MARK: - Actions

    func loadItems() {
        guard loadState != .loading else { return }
        loadState = .loading

        Task {
            do {
                let results = try await client.fetchPlaylistItems(playlistID: playlist.id)
                items = results
                loadState = .loaded
            } catch {
                loadState = .error(error.localizedDescription)
            }
        }
    }

    func reload() {
        items = []
        loadState = .idle
        loadItems()
    }
}

// MARK: - YouTubeSubscriptionsViewModel

@MainActor
final class YouTubeSubscriptionsViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)

        static func == (lhs: LoadState, rhs: LoadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    @Published var subscriptions: [YouTubeSubscription] = []
    @Published var loadState: LoadState = .idle

    private let client: any YouTubePlaylistAPIClientProtocol

    init(client: any YouTubePlaylistAPIClientProtocol = YouTubePlaylistAPIClient.shared) {
        self.client = client
    }

    // MARK: - Actions

    func loadSubscriptions() {
        guard loadState != .loading else { return }
        loadState = .loading

        Task {
            do {
                let results = try await client.fetchMySubscriptions()
                subscriptions = results
                loadState = .loaded
            } catch {
                loadState = .error(error.localizedDescription)
            }
        }
    }

    func reload() {
        subscriptions = []
        loadState = .idle
        loadSubscriptions()
    }
}
