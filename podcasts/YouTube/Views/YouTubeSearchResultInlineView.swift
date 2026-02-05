import SwiftUI
import UIKit
import PocketCastsUtils

/// Inline view shown when a YouTube URL is detected in search results
struct YouTubeSearchResultInlineView: View {
    let urlString: String

    @State private var feed: YouTubeFeed?
    @State private var videos: [YouTubeVideo] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isSubscribed = false
    @State private var selectedVideo: YouTubeVideo?

    @EnvironmentObject var theme: Theme

    private let feedManager = YouTubeFeedManager.shared
    private let parser = YouTubeFeedParser.shared

    var body: some View {
        Group {
            if !parser.isAPIConfigured {
                apiNotConfiguredView
            } else if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if let feed = feed {
                feedDetailView(feed)
            }
        }
        .background(theme.primaryUi01)
        .task {
            if parser.isAPIConfigured {
                await loadFeed()
            }
        }
        .fullScreenCover(item: $selectedVideo) { video in
            YouTubePlayerView(video: video)
        }
    }

    @ViewBuilder
    private var apiNotConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("YouTube API Not Configured")
                .font(.headline)
                .foregroundColor(theme.primaryText01)

            Text("To use YouTube feeds, you need to configure a YouTube Data API key.")
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Link("Get an API Key", destination: URL(string: "https://console.cloud.google.com/apis/credentials")!)
                .font(.subheadline)
                .foregroundColor(theme.primaryInteractive01)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.loadingActivityColor().color)
            Text("Loading YouTube feed...")
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
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
                .foregroundColor(theme.primaryText01)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await loadFeed()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func feedDetailView(_ feed: YouTubeFeed) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Feed header
                feedHeaderView(feed)
                    .padding()

                Divider()
                    .background(theme.primaryUi05)

                // Videos list
                if !videos.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(videos) { video in
                            YouTubeVideoCell(video: video) {
                                openVideo(video)
                            }

                            Divider()
                                .background(theme.primaryUi05)
                                .padding(.leading, 132)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func feedHeaderView(_ feed: YouTubeFeed) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Channel icon
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(feed.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText01)

                    if let author = feed.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText02)
                    }

                    Text("\(videos.count) videos")
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                }

                Spacer()
            }

            // Subscribe button
            Button {
                toggleSubscription()
            } label: {
                HStack {
                    Image(systemName: isSubscribed ? "checkmark" : "plus")
                    Text(isSubscribed ? "Added" : "Add to My YouTube Feeds")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSubscribed ? Color.green.opacity(0.2) : theme.primaryInteractive01)
                .foregroundColor(isSubscribed ? .green : .white)
                .cornerRadius(8)
            }

            if isSubscribed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You can find this feed in Profile → My YouTube Feeds")
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                }
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
            FileLog.shared.addMessage("YouTubeSearchResultInlineView: Error loading feed - \(error)")

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
        selectedVideo = video

        Analytics.track(.youTubeVideoOpened, properties: [
            "feed_id": video.feedId,
            "video_id": video.id
        ])
    }
}

// MARK: - Preview

#Preview {
    YouTubeSearchResultInlineView(urlString: "https://www.youtube.com/channel/UCxxx123")
        .environmentObject(Theme.sharedTheme)
}
