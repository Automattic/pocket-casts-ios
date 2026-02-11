import SwiftUI
import PocketCastsUtils

// MARK: - YouTubePlaylistListView

/// Shows the authenticated user's YouTube playlists
struct YouTubePlaylistListView: View {

    @EnvironmentObject private var theme: Theme
    @ObservedObject private var authManager = YouTubePlaylistAuthManager.shared
    @StateObject private var viewModel = YouTubePlaylistListViewModel()

    @State private var showConnectSheet = false

    var body: some View {
        Group {
            if authManager.isSignedIn {
                playlistsContent
            } else {
                notConnectedPlaceholder
            }
        }
        .navigationTitle("YouTube Playlists")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if authManager.isSignedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            authManager.signOut()
                        } label: {
                            Label("Disconnect YouTube", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showConnectSheet) {
            YouTubePlaylistConnectView {
                showConnectSheet = false
                viewModel.loadPlaylists()
            }
            .environmentObject(theme)
        }
        .onAppear {
            if authManager.isSignedIn && viewModel.loadState == .idle {
                viewModel.loadPlaylists()
            }
        }
        .onChange(of: authManager.isSignedIn) { isSignedIn in
            if isSignedIn {
                viewModel.loadPlaylists()
            } else {
                viewModel.playlists = []
                viewModel.loadState = .idle
            }
        }
    }

    // MARK: - Playlists Content

    @ViewBuilder
    private var playlistsContent: some View {
        switch viewModel.loadState {
        case .idle:
            Color.clear.onAppear { viewModel.loadPlaylists() }

        case .loading:
            VStack {
                Spacer()
                ProgressView()
                    .tint(AppTheme.loadingActivityColor().color)
                Spacer()
            }

        case .loaded where viewModel.playlists.isEmpty:
            emptyPlaceholder(
                icon: "music.note.list",
                title: "No Playlists Found",
                message: "You don't have any YouTube playlists yet."
            )

        case .loaded:
            List(viewModel.playlists) { playlist in
                NavigationLink {
                    YouTubePlaylistDetailView(
                        viewModel: YouTubePlaylistDetailViewModel(playlist: playlist)
                    )
                    .environmentObject(theme)
                } label: {
                    YouTubePlaylistRow(playlist: playlist)
                }
                .listRowBackground(theme.primaryUi01)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.primaryUi01.ignoresSafeArea())
            .refreshable { viewModel.reload() }

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Not Connected Placeholder

    private var notConnectedPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 52))
                .foregroundColor(theme.primaryInteractive01)
            Text("YouTube Not Connected")
                .font(.title2.bold())
                .foregroundColor(theme.primaryText01)
            Text("Connect your Google account to browse your YouTube playlists.")
                .font(.body)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showConnectSheet = true
            } label: {
                Text("Connect YouTube")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primaryInteractive01)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01.ignoresSafeArea())
    }

    // MARK: - Helpers

    private func emptyPlaceholder(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(theme.primaryIcon02)
            Text(title)
                .font(.headline)
                .foregroundColor(theme.primaryText01)
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01.ignoresSafeArea())
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundColor(.red)
            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(theme.primaryText01)
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") { viewModel.reload() }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01.ignoresSafeArea())
    }
}

// MARK: - YouTubePlaylistRow

private struct YouTubePlaylistRow: View {
    @EnvironmentObject private var theme: Theme
    let playlist: YouTubeUserPlaylist

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 64, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(2)

                Text("\(playlist.itemCount) video\(playlist.itemCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(theme.primaryText02)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = playlist.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderThumbnail
                case .empty:
                    placeholderThumbnail
                        .overlay(ProgressView().tint(AppTheme.loadingActivityColor().color))
                @unknown default:
                    placeholderThumbnail
                }
            }
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        Rectangle()
            .fill(theme.primaryUi05)
            .overlay(
                Image(systemName: "play.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(theme.primaryIcon02)
            )
    }
}
