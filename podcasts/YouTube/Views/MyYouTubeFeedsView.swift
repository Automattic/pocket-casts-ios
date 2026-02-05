import SwiftUI
import UIKit
import PocketCastsUtils

/// View model for the My YouTube Feeds screen
@MainActor
class MyYouTubeFeedsViewModel: ObservableObject {
    @Published var feeds: [YouTubeFeed] = []
    @Published var isLoading = false

    private let feedManager = YouTubeFeedManager.shared

    init() {
        loadFeeds()
        setupNotifications()
    }

    func loadFeeds() {
        feeds = feedManager.allFeeds().sorted { $0.addedDate > $1.addedDate }
    }

    func deleteFeed(_ feed: YouTubeFeed) {
        feedManager.removeFeed(feed)
        loadFeeds()
    }

    func deleteFeed(at offsets: IndexSet) {
        for index in offsets {
            let feed = feeds[index]
            feedManager.removeFeed(feed)
        }
        loadFeeds()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .youTubeFeedAdded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadFeeds()
        }

        NotificationCenter.default.addObserver(
            forName: .youTubeFeedRemoved,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadFeeds()
        }

        NotificationCenter.default.addObserver(
            forName: .youTubeFeedUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadFeeds()
        }
    }
}

/// A cell displaying a YouTube feed in the list
struct YouTubeFeedCell: View {
    let feed: YouTubeFeed

    var body: some View {
        HStack(spacing: 12) {
            // Channel icon placeholder
            Circle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let author = feed.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text("\(feed.videoCount) videos")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastUpdated = feed.lastUpdatedDate {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(formatDate(lastUpdated))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// List view showing all saved YouTube feeds
struct MyYouTubeFeedsView: View {
    @StateObject private var viewModel = MyYouTubeFeedsViewModel()
    @State private var selectedFeed: YouTubeFeed?

    var body: some View {
        Group {
            if viewModel.feeds.isEmpty {
                emptyView
            } else {
                feedListView
            }
        }
        .navigationTitle("My YouTube Feeds")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No YouTube Feeds")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add YouTube channels by pasting their URL in the search bar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var feedListView: some View {
        List {
            ForEach(viewModel.feeds) { feed in
                NavigationLink {
                    YouTubeFeedDetailView(feed: feed)
                } label: {
                    YouTubeFeedCell(feed: feed)
                }
            }
            .onDelete(perform: viewModel.deleteFeed)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - UIKit Wrapper

class MyYouTubeFeedsViewController: UIHostingController<AnyView> {
    init() {
        super.init(rootView: AnyView(NavigationStack { MyYouTubeFeedsView() }))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        Analytics.track(.myYouTubeFeedsShown)
    }
}

/// A standalone view controller that can be pushed onto a navigation stack
class MyYouTubeFeedsListViewController: UIHostingController<MyYouTubeFeedsView> {
    init() {
        super.init(rootView: MyYouTubeFeedsView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My YouTube Feeds"
        navigationItem.largeTitleDisplayMode = .never
        Analytics.track(.myYouTubeFeedsShown)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MyYouTubeFeedsView()
    }
}
