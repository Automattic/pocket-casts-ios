import SwiftUI
import UIKit
import PocketCastsUtils

/// View model for the YouTube feed detail screen
@MainActor
class YouTubeFeedDetailViewModel: ObservableObject {
    let feed: YouTubeFeed

    @Published var videos: [YouTubeVideo] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isSubscribed: Bool

    private let feedManager = YouTubeFeedManager.shared
    private let parser = YouTubeFeedParser.shared

    init(feed: YouTubeFeed) {
        self.feed = feed
        self.isSubscribed = feedManager.feedExists(withId: feed.id)

        // Load cached videos first
        self.videos = feedManager.videos(forFeedId: feed.id)
    }

    func loadVideos() async {
        isLoading = true
        error = nil

        do {
            let fetchedVideos = try await parser.refreshFeed(feed)
            videos = fetchedVideos

            // Cache the videos if subscribed
            if isSubscribed {
                feedManager.saveVideos(fetchedVideos, forFeedId: feed.id)
            }
        } catch {
            self.error = error
            FileLog.shared.addMessage("YouTubeFeedDetailViewModel: Error loading videos - \(error)")
        }

        isLoading = false
    }

    func subscribe() {
        feedManager.addFeed(feed)
        feedManager.saveVideos(videos, forFeedId: feed.id)
        isSubscribed = true

        Analytics.track(.youTubeFeedSubscribed, properties: ["feed_id": feed.id])
    }

    func unsubscribe() {
        feedManager.removeFeed(feed)
        isSubscribed = false

        Analytics.track(.youTubeFeedUnsubscribed, properties: ["feed_id": feed.id])
    }

    func openVideo(_ video: YouTubeVideo) {
        guard let url = video.watchURL else { return }
        UIApplication.shared.open(url)

        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": feed.id,
            "video_id": video.id
        ])
    }
}

/// Detail view for a YouTube feed showing its videos
struct YouTubeFeedDetailView: View {
    @StateObject private var viewModel: YouTubeFeedDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideo: YouTubeVideo?

    init(feed: YouTubeFeed) {
        _viewModel = StateObject(wrappedValue: YouTubeFeedDetailViewModel(feed: feed))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.videos.isEmpty {
                loadingView
            } else if let error = viewModel.error, viewModel.videos.isEmpty {
                errorView(error)
            } else if viewModel.videos.isEmpty {
                emptyView
            } else {
                videoListView
            }
        }
        .navigationTitle(viewModel.feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                subscribeButton
            }
        }
        .task {
            await viewModel.loadVideos()
        }
        .refreshable {
            await viewModel.loadVideos()
        }
        .fullScreenCover(item: $selectedVideo) { video in
            YouTubePlayerView(video: video)
        }
    }

    private func playVideo(_ video: YouTubeVideo) {
        selectedVideo = video
        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": viewModel.feed.id,
            "video_id": video.id
        ])
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading videos...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Failed to load videos")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await viewModel.loadVideos()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No videos found")
                .font(.headline)

            Text("This channel doesn't have any videos yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var videoListView: some View {
        List {
            // Header section
            Section {
                feedHeaderView
            }

            // Videos section
            Section {
                ForEach(viewModel.videos) { video in
                    YouTubeVideoCell(video: video) {
                        playVideo(video)
                    }
                    .listRowInsets(EdgeInsets())
                }
            } header: {
                Text("\(viewModel.videos.count) videos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var feedHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let author = viewModel.feed.author {
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let description = viewModel.feed.feedDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if let channelURL = viewModel.feed.channelURL,
               let url = URL(string: channelURL) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on YouTube")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var subscribeButton: some View {
        Button {
            if viewModel.isSubscribed {
                viewModel.unsubscribe()
            } else {
                viewModel.subscribe()
            }
        } label: {
            Image(systemName: viewModel.isSubscribed ? "checkmark.circle.fill" : "plus.circle")
                .foregroundColor(viewModel.isSubscribed ? .green : .accentColor)
        }
    }
}

// MARK: - UIKit Wrapper

class YouTubeFeedDetailViewController: UIHostingController<YouTubeFeedDetailView> {
    init(feed: YouTubeFeed) {
        super.init(rootView: YouTubeFeedDetailView(feed: feed))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.track(.youTubeFeedShown)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        YouTubeFeedDetailView(feed: YouTubeFeed.preview())
    }
}
