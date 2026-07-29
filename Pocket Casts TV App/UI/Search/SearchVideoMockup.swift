import SwiftUI

// MARK: - Search Screen with Video Integration

/// Mockup showing how Search could surface video content:
/// 1. Pre-search state: browsable video podcasts section
/// 2. Results: video podcasts get landscape thumbnail + badge, mixed with regular results
/// 3. A "Video" search scope filter
struct SearchVideoMockup: View {

    @State private var searchText: String
    @State private var scope: MockSearchScope

    init(searchText: String = "", scope: MockSearchScope = .all) {
        _searchText = State(initialValue: searchText)
        _scope = State(initialValue: scope)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Scope picker
                Picker("Scope", selection: $scope) {
                    ForEach(MockSearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 80)
                .padding(.bottom, 24)

                if searchText.isEmpty {
                    preSearchView
                } else {
                    searchResultsView
                }
            }
            .searchable(text: $searchText, prompt: "Search podcasts & episodes")
        }
    }

    // MARK: - Pre-Search State

    /// Before the user types, show browsable video content
    var preSearchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 80) {
                // Popular Video Podcasts section
                MockHomeSection(title: "Popular Video Podcasts") {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 48) {
                            ForEach(MockSearchVideoData.popularVideoPodcasts) { item in
                                VideoPodcastSearchCard(item: item)
                            }
                        }
                    }
                }

                // Browse Video by Category
                MockHomeSection(title: "Browse Video by Category") {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 32) {
                            ForEach(MockSearchVideoData.videoCategories, id: \.self) { category in
                                VideoCategoryPill(name: category)
                            }
                        }
                    }
                }

                // Recently Added Video Podcasts
                MockHomeSection(title: "Recently Added") {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 48) {
                            ForEach(MockSearchVideoData.recentlyAdded) { item in
                                VideoPodcastSearchCard(item: item)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Search Results

    var searchResultsView: some View {
        ScrollView {
            switch scope {
            case .all:
                mixedResultsGrid
            case .podcasts:
                podcastOnlyGrid
            case .episodes:
                episodeOnlyGrid
            case .video:
                videoOnlyGrid
            }
        }
    }

    /// All results: podcasts (square) and video podcasts (wider with badge) mixed together
    var mixedResultsGrid: some View {
        VStack(alignment: .leading, spacing: 60) {
            // Video results shown prominently at top when relevant
            if !MockSearchVideoData.videoResults.isEmpty {
                MockHomeSection(title: "Video Results") {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 48) {
                            ForEach(MockSearchVideoData.videoResults) { item in
                                VideoSearchResultCard(item: item)
                            }
                        }
                    }
                }
            }

            // Regular podcast results grid
            MockHomeSection(title: "Podcasts") {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(250), spacing: 48), count: 6), spacing: 48) {
                    ForEach(0..<12) { i in
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pcBackgroundOverlay)
                                    .frame(width: 250, height: 250)

                                // Show video badge on podcasts that have video
                                if i == 2 || i == 5 || i == 8 {
                                    videoBadge
                                }
                            }
                            Text(MockSearchVideoData.podcastNames[i % MockSearchVideoData.podcastNames.count])
                                .font(.caption2)
                                .foregroundStyle(Color.pcTextSecondary)
                                .lineLimit(1)
                                .frame(width: 250)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 40)
    }

    var podcastOnlyGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(250), spacing: 48), count: 6), spacing: 48) {
            ForEach(0..<18) { i in
                VStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pcBackgroundOverlay)
                            .frame(width: 250, height: 250)
                        if i == 1 || i == 4 || i == 7 || i == 11 {
                            videoBadge
                        }
                    }
                    Text(MockSearchVideoData.podcastNames[i % MockSearchVideoData.podcastNames.count])
                        .font(.caption2)
                        .foregroundStyle(Color.pcTextSecondary)
                        .lineLimit(1)
                        .frame(width: 250)
                }
            }
        }
        .padding(.vertical, 40)
    }

    var episodeOnlyGrid: some View {
        LazyVStack(spacing: 24) {
            ForEach(MockSearchVideoData.episodeResults) { item in
                if item.isVideo {
                    VideoEpisodeSearchRow(item: item)
                } else {
                    AudioEpisodeSearchRow(item: item)
                }
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 80)
    }

    /// Video scope: only video podcasts and video episodes
    var videoOnlyGrid: some View {
        VStack(alignment: .leading, spacing: 60) {
            MockHomeSection(title: "Video Podcasts") {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 48) {
                        ForEach(MockSearchVideoData.videoResults) { item in
                            VideoSearchResultCard(item: item)
                        }
                    }
                }
            }

            MockHomeSection(title: "Video Episodes") {
                LazyVStack(spacing: 24) {
                    ForEach(MockSearchVideoData.episodeResults.filter(\.isVideo)) { item in
                        VideoEpisodeSearchRow(item: item)
                    }
                }
                .padding(.horizontal, 80)
            }
        }
        .padding(.vertical, 40)
    }

    var videoBadge: some View {
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
}

// MARK: - Video Search Result Card

/// Landscape card for video podcast results — visually distinct from square podcast art
struct VideoSearchResultCard: View {

    let item: MockSearchItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pcBackgroundOverlay)
                    .frame(width: 400, height: 225)
                    .overlay {
                        Image(systemName: "video.fill")
                            .font(.title2)
                            .foregroundStyle(Color.pcTextSecondary.opacity(0.4))
                    }

                // Podcast art overlay
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pcBackgroundBase)
                        .frame(width: 48, height: 48)
                    Text(item.podcastName)
                        .font(.caption2)
                        .foregroundStyle(Color.pcTextPrimary)
                        .lineLimit(1)
                }
                .padding(12)
                .background {
                    LinearGradient(
                        colors: [.black.opacity(0.8), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.podcastName)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextPrimary)
                    .lineLimit(1)
                Text(item.author)
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 400)
    }
}

// MARK: - Video Podcast Search Card (Pre-search)

struct VideoPodcastSearchCard: View {
    let item: MockSearchItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pcBackgroundOverlay)
                    .frame(width: 250, height: 250)

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

// MARK: - Video Category Pill

struct VideoCategoryPill: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.headline)
            .foregroundStyle(Color.pcTextPrimary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.pcBackgroundOverlay)
            .clipShape(Capsule())
    }
}

// MARK: - Episode Search Rows

/// Video episode in search results — shows landscape thumbnail
struct VideoEpisodeSearchRow: View {
    let item: MockEpisodeSearchItem

    var body: some View {
        HStack(spacing: 24) {
            // Landscape thumbnail
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pcBackgroundOverlay)
                    .frame(width: 213, height: 120)
                    .overlay {
                        Image(systemName: "play.fill")
                            .foregroundStyle(Color.pcTextSecondary.opacity(0.5))
                    }

                // Duration pill
                Text(item.duration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.pcTextPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextPrimary)
                    .lineLimit(2)
                Text(item.podcastName)
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 10))
                        Text("Video")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.red)
                    Text("· \(item.date)")
                        .font(.caption2)
                        .foregroundStyle(Color.pcTextTertiary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.pcBackgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Standard audio episode in search results — square podcast art
struct AudioEpisodeSearchRow: View {
    let item: MockEpisodeSearchItem

    var body: some View {
        HStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.pcBackgroundOverlay)
                .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextPrimary)
                    .lineLimit(2)
                Text(item.podcastName)
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextSecondary)
                Text("\(item.duration) · \(item.date)")
                    .font(.caption2)
                    .foregroundStyle(Color.pcTextTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.pcBackgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Search Scope

enum MockSearchScope: String, CaseIterable {
    case all = "All"
    case podcasts = "Podcasts"
    case episodes = "Episodes"
    case video = "Video"
}

// MARK: - Mock Data

struct MockSearchItem: Identifiable {
    let id = UUID()
    let podcastName: String
    let author: String
}

struct MockEpisodeSearchItem: Identifiable {
    let id = UUID()
    let title: String
    let podcastName: String
    let duration: String
    let date: String
    let isVideo: Bool
}

enum MockSearchVideoData {

    static let videoCategories = [
        "Technology", "Business", "Bitcoin & Crypto", "Comedy",
        "News", "Education", "Health", "Arts"
    ]

    static let popularVideoPodcasts: [MockSearchItem] = [
        MockSearchItem(podcastName: "This Week in Tech", author: "TWiT"),
        MockSearchItem(podcastName: "TED Talks", author: "TED"),
        MockSearchItem(podcastName: "Daily Tech News Show", author: "Tom Merritt"),
        MockSearchItem(podcastName: "The Startup Ideas Podcast", author: "Greg Isenberg"),
        MockSearchItem(podcastName: "What Bitcoin Did", author: "Peter McCormack"),
        MockSearchItem(podcastName: "Think Fast Talk Smart", author: "Stanford GSB"),
    ]

    static let recentlyAdded: [MockSearchItem] = [
        MockSearchItem(podcastName: "TechSurge: Deep Tech", author: "TechSurge"),
        MockSearchItem(podcastName: "The Entrepreneur Experiment", author: "Various"),
        MockSearchItem(podcastName: "The Modern Manager", author: "Mamie Kanfer Stewart"),
        MockSearchItem(podcastName: "SPEAK LIKE A CEO", author: "Oliver Aust"),
        MockSearchItem(podcastName: "Dad Tired", author: "Jerrad Lopes"),
        MockSearchItem(podcastName: "Primary Technology", author: "Primary"),
    ]

    static let videoResults: [MockSearchItem] = [
        MockSearchItem(podcastName: "This Week in Tech", author: "TWiT"),
        MockSearchItem(podcastName: "Daily Tech News Show", author: "Tom Merritt"),
        MockSearchItem(podcastName: "TechSurge: Deep Tech", author: "TechSurge"),
    ]

    static let podcastNames = [
        "The Vergecast", "Accidental Tech Podcast", "This Week in Tech",
        "Daily Tech News Show", "Waveform", "Decoder",
        "TechSurge", "Rocket", "Connected", "Cortex",
        "Upgrade", "Mac Power Users", "Automators",
        "Swift by Sundell", "Under the Radar", "App Stories",
        "Whiskey Web and Whatnot", "Darknet Diaries"
    ]

    static let episodeResults: [MockEpisodeSearchItem] = [
        MockEpisodeSearchItem(title: "The Great Beagle Migration - Pope Leo XIV's 1st Encyclical & Ferrari's 1st EV", podcastName: "This Week in Tech", duration: "2h 15m", date: "2d ago", isVideo: true),
        MockEpisodeSearchItem(title: "The Practical Ferrari – DTNS Live 5129", podcastName: "Daily Tech News Show", duration: "35m", date: "Today", isVideo: true),
        MockEpisodeSearchItem(title: "Google I/O 2026 Reactions", podcastName: "The Vergecast", duration: "1h 20m", date: "3d ago", isVideo: false),
        MockEpisodeSearchItem(title: "Docker Deep Dive: Container Orchestration", podcastName: "DevOps and Docker Talk", duration: "52m", date: "Yesterday", isVideo: true),
        MockEpisodeSearchItem(title: "Apple's Next Big Thing", podcastName: "Accidental Tech Podcast", duration: "2h 05m", date: "1w ago", isVideo: false),
        MockEpisodeSearchItem(title: "Building with Swift 6.2", podcastName: "Swift by Sundell", duration: "45m", date: "4d ago", isVideo: false),
    ]
}

// MARK: - Previews

#Preview("Search — Pre-Search") {
    SearchVideoMockup()
        .background(Color.pcBackgroundSunken)
}

#Preview("Search — Results (All)") {
    SearchVideoMockup(searchText: "tech")
        .background(Color.pcBackgroundSunken)
}

#Preview("Search — Video Scope") {
    SearchVideoMockup(searchText: "tech", scope: .video)
        .background(Color.pcBackgroundSunken)
}

#Preview("Search — Episode Scope") {
    SearchVideoMockup(searchText: "tech", scope: .episodes)
        .background(Color.pcBackgroundSunken)
}
