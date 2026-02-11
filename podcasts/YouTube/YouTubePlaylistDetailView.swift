import SafariServices
import SwiftUI
import PocketCastsUtils

// MARK: - URL+Identifiable

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - YouTubePlaylistDetailView

/// Shows all videos in a single YouTube playlist
struct YouTubePlaylistDetailView: View {

    @EnvironmentObject private var theme: Theme
    @StateObject var viewModel: YouTubePlaylistDetailViewModel

    @State private var selectedVideoURL: URL?

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle:
                Color.clear.onAppear { viewModel.loadItems() }

            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.loadingActivityColor().color)
                    Spacer()
                }

            case .loaded where viewModel.items.isEmpty:
                emptyPlaceholder

            case .loaded:
                List(viewModel.items) { item in
                    Button {
                        playItem(item)
                    } label: {
                        YouTubePlaylistVideoRow(item: item)
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
        .navigationTitle(viewModel.playlist.title)
        .navigationBarTitleDisplayMode(.large)
        .background(theme.primaryUi01.ignoresSafeArea())
        .onAppear {
            if viewModel.loadState == .idle {
                viewModel.loadItems()
            }
        }
        .fullScreenCover(item: $selectedVideoURL) { url in
            SafariVideoPlayer(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Playback

    /// Opens the video in-app using SafariViewController (same as feeds)
    private func playItem(_ item: YouTubePlaylistVideo) {
        Analytics.track(.youTubePlaylistItemTapped)
        selectedVideoURL = item.watchURL
    }

    // MARK: - Helpers

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(theme.primaryIcon02)
            Text("Empty Playlist")
                .font(.headline)
                .foregroundColor(theme.primaryText01)
            Text("This playlist doesn't have any videos yet.")
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

// MARK: - YouTubePlaylistVideoRow

private struct YouTubePlaylistVideoRow: View {
    @EnvironmentObject private var theme: Theme
    let item: YouTubePlaylistVideo

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 96, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(2)

                if !item.channelTitle.isEmpty {
                    Text(item.channelTitle)
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                        .lineLimit(1)
                }

                if let date = item.publishedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = item.thumbnailURL {
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
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryIcon02)
            )
    }
}
