import SwiftUI

// MARK: - Home Screen with Enhanced Video Content

/// Mockup showing how the Home tab could surface more video content
/// alongside the existing rows.
struct HomeVideoMockup: View {

    enum Section: String {
        case continueWatching
        case newVideoEpisodes
        case videoPodcastsForYou
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 80) {
                    // Existing: Now Playing
                    MockHomeSection(title: "Keep Listening") {
                        mockNowPlayingRow
                    }

                    // NEW: Continue Watching
                    MockHomeSection(title: "Continue Watching") {
                        continueWatchingRow
                    }

                    // Existing: Up Next (unchanged)

                    // Existing: Recommended For You (unchanged)

                    // NEW: New Video Episodes (from subscribed video podcasts)
                    MockHomeSection(title: "New Video Episodes") {
                        newVideoEpisodesRow
                    }

                    // Existing: New Releases (audio, unchanged)
                    MockHomeSection(title: "New Releases") {
                        mockNewReleasesRow
                    }

                    // NEW: Video Podcasts You Might Like
                    MockHomeSection(title: "Video Podcasts You Might Like") {
                        videoPodcastsRow
                    }

                    // Existing: Trending, etc.
                    MockHomeSection(title: "Trending") {
                        mockTrendingRow
                    }
                }
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Continue Watching Row

    /// Shows in-progress video episodes with progress bars — like a streaming app
    var continueWatchingRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48) {
                ForEach(MockVideoData.continueWatching) { item in
                    ContinueWatchingCard(item: item)
                }
            }
        }
    }

    // MARK: - New Video Episodes Row

    /// Latest video episodes from subscribed video podcasts, using landscape cards
    var newVideoEpisodesRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48) {
                ForEach(MockVideoData.newVideoEpisodes) { item in
                    VideoEpisodeCard(item: item)
                }
            }
        }
    }

    // MARK: - Video Podcasts You Might Like

    /// Podcast-level recommendations filtered to video podcasts
    var videoPodcastsRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48) {
                ForEach(MockVideoData.videoPodcasts) { item in
                    VideoPodcastCard(item: item)
                }
            }
        }
    }

    // MARK: - Existing Row Placeholders

    var mockNowPlayingRow: some View {
        HStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pcBackgroundOverlay)
                .frame(width: 124, height: 124)
                .overlay {
                    Image(systemName: "waveform")
                        .foregroundStyle(Color.pcTextSecondary)
                }
            VStack(alignment: .leading, spacing: 8) {
                Text("The Search for Life Beyond Earth")
                    .font(.headline)
                    .foregroundStyle(Color.pcTextPrimary)
                Text("Radiolab")
                    .font(.subheadline)
                    .foregroundStyle(Color.pcTextSecondary)
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 1242, alignment: .leading)
        .background(Color.pcBackgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var mockNewReleasesRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 24) {
                ForEach(0..<6) { i in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pcBackgroundOverlay)
                            .frame(width: 124, height: 124)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(MockVideoData.audioTitles[i % MockVideoData.audioTitles.count])
                                .font(.caption)
                                .foregroundStyle(Color.pcTextPrimary)
                                .lineLimit(2)
                            Text("45 min")
                                .font(.caption2)
                                .foregroundStyle(Color.pcTextSecondary)
                        }
                    }
                    .frame(width: 864)
                    .padding(16)
                    .background(Color.pcBackgroundSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    var mockTrendingRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 48) {
                ForEach(0..<8) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pcBackgroundOverlay)
                        .frame(width: 250, height: 250)
                }
            }
        }
    }
}

// MARK: - Continue Watching Card

/// Landscape card with progress bar for in-progress video episodes
struct ContinueWatchingCard: View {

    let item: MockVideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video thumbnail area
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pcBackgroundOverlay)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.pcTextPrimary.opacity(0.5))
                    }

                // Progress bar at bottom
                GeometryReader { geo in
                    VStack {
                        Spacer()
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.pcTextSecondary.opacity(0.3))
                                .frame(height: 4)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * item.progress, height: 4)
                        }
                    }
                }
            }
            .frame(width: 480, height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.episodeTitle)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextPrimary)
                    .lineLimit(1)
                Text("\(item.podcastName) · \(item.remainingTime) left")
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
                    .lineLimit(1)
            }
            .padding(.top, 12)
        }
        .frame(width: 480)
    }
}

// MARK: - Video Episode Card

/// Landscape card for new video episodes (no progress bar)
struct VideoEpisodeCard: View {

    let item: MockVideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pcBackgroundOverlay)
                    .overlay {
                        Image(systemName: "video.fill")
                            .font(.title)
                            .foregroundStyle(Color.pcTextSecondary.opacity(0.5))
                    }

                // Podcast image + title overlay
                HStack(alignment: .bottom, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pcBackgroundBase)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.podcastName)
                            .font(.caption2)
                            .foregroundStyle(Color.pcTextSecondary)
                        Text(item.episodeTitle)
                            .font(.caption)
                            .foregroundStyle(Color.pcTextPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(16)
                .background {
                    LinearGradient(
                        colors: [.black, .black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            }
            .frame(width: 480, height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Duration + date
            HStack {
                Text(item.duration)
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
                Text("·")
                    .foregroundStyle(Color.pcTextTertiary)
                Text(item.date)
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
            }
            .padding(.top, 8)
        }
        .frame(width: 480)
    }
}

// MARK: - Video Podcast Card

/// Square podcast card with a video badge overlay
struct VideoPodcastCard: View {

    let item: MockVideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pcBackgroundOverlay)
                    .frame(width: 250, height: 250)

                // Video badge
                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 10))
                    Text("VIDEO")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.pcTextPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
            }

            Text(item.podcastName)
                .font(.caption)
                .foregroundStyle(Color.pcTextPrimary)
                .lineLimit(1)
            Text(item.author)
                .font(.caption2)
                .foregroundStyle(Color.pcTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 250)
    }
}

// MARK: - Mock Home Section

struct MockHomeSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(title)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
    }
}

// MARK: - Mock Data

struct MockVideoItem: Identifiable {
    let id = UUID()
    let episodeTitle: String
    let podcastName: String
    let author: String
    let duration: String
    let date: String
    let progress: CGFloat
    let remainingTime: String
}

enum MockVideoData {

    static let continueWatching: [MockVideoItem] = [
        MockVideoItem(episodeTitle: "The Great Beagle Migration - Pope Leo XIV's 1st Encyclical", podcastName: "This Week in Tech", author: "TWiT", duration: "2h 15m", date: "2d ago", progress: 0.65, remainingTime: "47 min"),
        MockVideoItem(episodeTitle: "Building Startups in the Age of AI", podcastName: "The Startup Ideas Podcast", author: "Greg Isenberg", duration: "1h 32m", date: "3d ago", progress: 0.3, remainingTime: "1h 4m"),
        MockVideoItem(episodeTitle: "Bitcoin's Next Halving - What to Expect", podcastName: "What Bitcoin Did", author: "Peter McCormack", duration: "1h 45m", date: "1d ago", progress: 0.8, remainingTime: "21 min"),
    ]

    static let newVideoEpisodes: [MockVideoItem] = [
        MockVideoItem(episodeTitle: "The Practical Ferrari – DTNS Live 5129", podcastName: "Daily Tech News Show", author: "Tom Merritt", duration: "35m", date: "Today", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "Think Fast Talk Smart: Communication Techniques", podcastName: "Think Fast Talk Smart", author: "Stanford GSB", duration: "28m", date: "Today", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "An 11-year-old prodigy performs old-school jazz", podcastName: "TED Talks Music", author: "TED", duration: "15m", date: "Yesterday", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "Docker Deep Dive: Container Orchestration in 2026", podcastName: "DevOps and Docker Talk", author: "Bret Fisher", duration: "52m", date: "Yesterday", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "A Bit of Optimism with Simon Sinek", podcastName: "A Bit of Optimism", author: "Simon Sinek", duration: "42m", date: "2d ago", progress: 0, remainingTime: ""),
    ]

    static let videoPodcasts: [MockVideoItem] = [
        MockVideoItem(episodeTitle: "", podcastName: "TFTC: A Bitcoin Podcast", author: "Marty Bent", duration: "", date: "", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "", podcastName: "The Startup Ideas Podcast", author: "Greg Isenberg", duration: "", date: "", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "", podcastName: "Female Startup Club", author: "Doone Roisin", duration: "", date: "", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "", podcastName: "Right About Now", author: "Ryan Alford", duration: "", date: "", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "", podcastName: "TechSurge: Deep Tech", author: "TechSurge Media", duration: "", date: "", progress: 0, remainingTime: ""),
        MockVideoItem(episodeTitle: "", podcastName: "Whiskey Web and Whatnot", author: "RobbieTheWagner", duration: "", date: "", progress: 0, remainingTime: ""),
    ]

    static let audioTitles = [
        "Why We Procrastinate",
        "The Hidden Cost of Fast Fashion",
        "How Memory Works (and Fails)",
        "The Science of Addiction",
        "The Future of Work",
        "How Cults Recruit Normal People",
    ]
}

// MARK: - Preview

#Preview("Home with Video") {
    HomeVideoMockup()
        .background(Color.pcBackgroundSunken)
}
