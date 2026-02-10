import SwiftUI
import UIKit
import PocketCastsUtils

/// View shown when a YouTube URL is detected in search
struct YouTubeSearchResultView: View {
    let urlString: String
    let onDismiss: () -> Void

    @State private var feed: YouTubeFeed?
    @State private var videos: [YouTubeVideo] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isSubscribed = false

    private let feedManager = YouTubeFeedManager.shared
    private let parser = YouTubeFeedParser.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if let feed = feed {
                    feedDetailView(feed)
                }
            }
            .navigationTitle("YouTube Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }

                if feed != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        subscribeButton
                    }
                }
            }
        }
        .task {
            await loadFeed()
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading YouTube feed...")
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

            Text("Could not load feed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await loadFeed()
                }
            }
            .buttonStyle(.bordered)

            Button("Cancel") {
                onDismiss()
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func feedDetailView(_ feed: YouTubeFeed) -> some View {
        List {
            // Feed header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(feed.title)
                                .font(.title3)
                                .fontWeight(.semibold)

                            if let author = feed.author {
                                Text(author)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(videos.count) videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if isSubscribed {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added to My YouTube Feeds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Videos section
            if !videos.isEmpty {
                Section {
                    ForEach(videos.prefix(15)) { video in
                        YouTubeVideoCell(video: video) {
                            openVideo(video)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text("Latest Videos")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var subscribeButton: some View {
        Button {
            toggleSubscription()
        } label: {
            if isSubscribed {
                Label("Added", systemImage: "checkmark")
                    .foregroundColor(.green)
            } else {
                Label("Add", systemImage: "plus")
            }
        }
    }

    private func loadFeed() async {
        isLoading = true
        error = nil

        do {
            let result = try await parser.fetchFeed(from: urlString)
            feed = result.feed
            videos = result.videos
            isSubscribed = feedManager.feedExists(withId: result.feed.id)

            Analytics.track(.youTubeFeedLoaded, properties: [
                "feed_id": result.feed.id,
                "video_count": result.videos.count
            ])
        } catch {
            self.error = error
            FileLog.shared.addMessage("YouTubeSearchResultView: Error loading feed - \(error)")

            Analytics.track(.youTubeFeedLoadFailed, properties: [
                "error": error.localizedDescription
            ])
        }

        isLoading = false
    }

    private func toggleSubscription() {
        guard let feed = feed else { return }

        if isSubscribed {
            feedManager.removeFeed(feed)
            isSubscribed = false
            Analytics.track(.youTubeFeedUnsubscribed, properties: ["feed_id": feed.id])
        } else {
            feedManager.addFeed(feed)
            feedManager.saveVideos(videos, forFeedId: feed.id)
            isSubscribed = true
            Analytics.track(.youTubeFeedSubscribed, properties: ["feed_id": feed.id])
        }
    }

    private func openVideo(_ video: YouTubeVideo) {
        guard let url = video.watchURL else { return }
        UIApplication.shared.open(url)

        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": video.feedId,
            "video_id": video.id
        ])
    }
}

// MARK: - UIKit Wrapper

class YouTubeSearchResultViewController: UIHostingController<YouTubeSearchResultView> {
    init(urlString: String, onDismiss: @escaping () -> Void) {
        super.init(rootView: YouTubeSearchResultView(urlString: urlString, onDismiss: onDismiss))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Preview

#Preview {
    YouTubeSearchResultView(
        urlString: "https://www.youtube.com/channel/UCxxx123",
        onDismiss: {}
    )
}
