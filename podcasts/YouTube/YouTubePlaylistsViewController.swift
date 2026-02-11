import SwiftUI
import UIKit
import PocketCastsUtils

// MARK: - YouTubePlaylistsViewController

/// UIViewController that hosts the YouTube Playlists & Subscriptions SwiftUI feature
///
/// Use this to push from ProfileViewController:
/// ```
/// let playlistsVC = YouTubePlaylistsViewController()
/// navigationController?.pushViewController(playlistsVC, animated: true)
/// ```
final class YouTubePlaylistsViewController: UIHostingController<AnyView> {

    init() {
        let rootView = AnyView(
            YouTubePlaylistsRootView()
                .environmentObject(Theme.sharedTheme)
        )
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Use init() instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Transparent background so theme color shows through
        view.backgroundColor = .clear
    }
}

// MARK: - Root SwiftUI Wrapper

/// Provides NavigationStack with tabs for playlists and subscriptions
private struct YouTubePlaylistsRootView: View {
    @EnvironmentObject private var theme: Theme
    @State private var selectedTab: YouTubeTab = .playlists

    enum YouTubeTab: String, CaseIterable {
        case playlists = "Playlists"
        case subscriptions = "Subscriptions"
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                contentView
            }
            .tint(theme.primaryInteractive01)
        } else {
            NavigationView {
                contentView
            }
            .navigationViewStyle(.stack)
            .tint(theme.primaryInteractive01)
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            // Segmented control for tabs
            Picker("", selection: $selectedTab) {
                ForEach(YouTubeTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Content based on selected tab
            switch selectedTab {
            case .playlists:
                YouTubePlaylistListView()
                    .environmentObject(theme)
            case .subscriptions:
                YouTubeSubscriptionsView { subscription in
                    subscribeToChannel(subscription)
                }
                .environmentObject(theme)
            }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
        .navigationTitle("YouTube")
        .navigationBarTitleDisplayMode(.large)
    }

    private func subscribeToChannel(_ subscription: YouTubeSubscription) {
        // Create a YouTubeFeed from the subscription and add it
        let feed = YouTubeFeed(
            id: subscription.channelID,
            title: subscription.title,
            author: subscription.title,
            feedDescription: subscription.description,
            thumbnailURL: subscription.thumbnailURL?.absoluteString,
            feedURL: subscription.rssFeedURL.absoluteString,
            channelURL: subscription.channelURL.absoluteString
        )

        // Check if already subscribed
        if YouTubeFeedManager.shared.feedExists(withId: subscription.channelID) {
            print("[YouTubeSubscriptions] Already subscribed to: \(subscription.title)")
            return
        }

        // Add the feed
        YouTubeFeedManager.shared.addFeed(feed)
        print("[YouTubeSubscriptions] Subscribed to: \(subscription.title)")

        // Track analytics
        Analytics.track(.youTubeSubscriptionAdded)
    }
}
