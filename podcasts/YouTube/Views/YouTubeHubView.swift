import SwiftUI
import PocketCastsUtils

// MARK: - YouTubeHubView

/// Unified YouTube experience combining Feeds, Playlists, and Subscriptions
struct YouTubeHubView: View {

    @EnvironmentObject private var theme: Theme
    @ObservedObject private var authManager = YouTubePlaylistAuthManager.shared
    @State private var selectedTab: YouTubeHubTab = .feeds

    enum YouTubeHubTab: String, CaseIterable {
        case feeds = "Feeds"
        case playlists = "Playlists"
        case subscriptions = "Channels"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Account status banner
            if !authManager.isSignedIn {
                connectBanner
            }

            // Tab selector
            Picker("", selection: $selectedTab) {
                ForEach(YouTubeHubTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Content
            tabContent
        }
        .background(theme.primaryUi01.ignoresSafeArea())
        .navigationTitle("YouTube")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                accountMenu
            }
        }
    }

    // MARK: - Connect Banner

    private var connectBanner: some View {
        Button {
            // This will show the connect view embedded in the tab content
            if selectedTab == .feeds {
                selectedTab = .playlists
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryInteractive01)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect YouTube Account")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.primaryText01)
                    Text("Access your playlists and subscriptions")
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.primaryText02)
            }
            .padding(12)
            .background(theme.primaryUi02)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Account Menu

    @ViewBuilder
    private var accountMenu: some View {
        Menu {
            if authManager.isSignedIn {
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    Label("Disconnect Account", systemImage: "person.crop.circle.badge.xmark")
                }
            }
        } label: {
            Image(systemName: authManager.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle")
                .foregroundColor(authManager.isSignedIn ? theme.primaryInteractive01 : theme.primaryIcon02)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .feeds:
            YouTubeHubFeedsView()
                .environmentObject(theme)

        case .playlists:
            if authManager.isSignedIn {
                YouTubeHubPlaylistsView()
                    .environmentObject(theme)
            } else {
                connectPromptView(
                    title: "Access Your Playlists",
                    message: "Connect your YouTube account to browse and play videos from your playlists."
                )
            }

        case .subscriptions:
            if authManager.isSignedIn {
                YouTubeHubSubscriptionsView()
                    .environmentObject(theme)
            } else {
                connectPromptView(
                    title: "Import Your Subscriptions",
                    message: "Connect your YouTube account to see channels you're subscribed to and add them to Pocket Casts."
                )
            }
        }
    }

    // MARK: - Connect Prompt

    private func connectPromptView(title: String, message: String) -> some View {
        YouTubeConnectPromptView(title: title, message: message)
            .environmentObject(theme)
    }
}

// MARK: - Connect Prompt View

private struct YouTubeConnectPromptView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject private var authManager = YouTubePlaylistAuthManager.shared

    let title: String
    let message: String

    @State private var showingSignIn = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "play.rectangle.on.rectangle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.primaryInteractive01)

            Text(title)
                .font(.title2.bold())
                .foregroundColor(theme.primaryText01)

            Text(message)
                .font(.body)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingSignIn = true
            } label: {
                HStack(spacing: 8) {
                    if authManager.isBusy {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                    }
                    Text("Connect YouTube")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(theme.primaryInteractive01)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(authManager.isBusy)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01)
        .sheet(isPresented: $showingSignIn) {
            YouTubePlaylistConnectView {
                showingSignIn = false
            }
            .environmentObject(theme)
        }
    }
}

// MARK: - Feeds Tab Content

private struct YouTubeHubFeedsView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = MyYouTubeFeedsViewModel()

    var body: some View {
        Group {
            if viewModel.feeds.isEmpty {
                emptyFeedsView
            } else {
                feedsList
            }
        }
    }

    private var emptyFeedsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryIcon02)

            Text("No Feeds Yet")
                .font(.headline)
                .foregroundColor(theme.primaryText01)

            Text("Add YouTube channels by pasting their URL in the search bar, or import from your Subscriptions.")
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01)
    }

    private var feedsList: some View {
        List {
            ForEach(viewModel.feeds) { feed in
                NavigationLink {
                    YouTubeFeedDetailView(feed: feed)
                        .environmentObject(theme)
                } label: {
                    YouTubeHubFeedRow(feed: feed)
                }
                .listRowBackground(theme.primaryUi01)
            }
            .onDelete(perform: viewModel.deleteFeed)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryUi01)
        .refreshable { viewModel.loadFeeds() }
    }
}

// MARK: - Feed Row

private struct YouTubeHubFeedRow: View {
    @EnvironmentObject private var theme: Theme
    let feed: YouTubeFeed

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let urlString = feed.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholderIcon
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                placeholderIcon
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feed.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(1)

                Text("\(feed.videoCount) videos")
                    .font(.caption)
                    .foregroundColor(theme.primaryText02)
            }
        }
        .padding(.vertical, 4)
    }

    private var placeholderIcon: some View {
        Circle()
            .fill(Color.red.opacity(0.8))
            .overlay(
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            )
    }
}

// MARK: - Playlists Tab Content

private struct YouTubeHubPlaylistsView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = YouTubePlaylistListViewModel()

    var body: some View {
        Group {
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
                emptyView

            case .loaded:
                playlistsList

            case .error(let message):
                errorView(message: message)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundColor(theme.primaryIcon02)
            Text("No Playlists Found")
                .font(.headline)
                .foregroundColor(theme.primaryText01)
            Text("You don't have any YouTube playlists yet.")
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01)
    }

    private var playlistsList: some View {
        List(viewModel.playlists) { playlist in
            NavigationLink {
                YouTubePlaylistDetailView(
                    viewModel: YouTubePlaylistDetailViewModel(playlist: playlist)
                )
                .environmentObject(theme)
            } label: {
                YouTubeHubPlaylistRow(playlist: playlist)
            }
            .listRowBackground(theme.primaryUi01)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryUi01)
        .refreshable { viewModel.reload() }
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
        .background(theme.primaryUi01)
    }
}

// MARK: - Playlist Row

private struct YouTubeHubPlaylistRow: View {
    @EnvironmentObject private var theme: Theme
    let playlist: YouTubeUserPlaylist

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = playlist.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholderIcon
                    }
                }
                .frame(width: 64, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                placeholderIcon
                    .frame(width: 64, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

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

    private var placeholderIcon: some View {
        Rectangle()
            .fill(theme.primaryUi05)
            .overlay(
                Image(systemName: "play.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(theme.primaryIcon02)
            )
    }
}

// MARK: - Subscriptions Tab Content

private struct YouTubeHubSubscriptionsView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = YouTubeSubscriptionsViewModel()

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle:
                Color.clear.onAppear { viewModel.loadSubscriptions() }

            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.loadingActivityColor().color)
                    Spacer()
                }

            case .loaded where viewModel.subscriptions.isEmpty:
                emptyView

            case .loaded:
                subscriptionsList

            case .error(let message):
                errorView(message: message)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 44))
                .foregroundColor(theme.primaryIcon02)
            Text("No Subscriptions Found")
                .font(.headline)
                .foregroundColor(theme.primaryText01)
            Text("You're not subscribed to any YouTube channels yet.")
                .font(.subheadline)
                .foregroundColor(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(theme.primaryUi01)
    }

    private var subscriptionsList: some View {
        List(viewModel.subscriptions) { subscription in
            YouTubeHubSubscriptionRow(subscription: subscription)
                .listRowBackground(theme.primaryUi01)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryUi01)
        .refreshable { viewModel.reload() }
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
        .background(theme.primaryUi01)
    }
}

// MARK: - Subscription Row

private struct YouTubeHubSubscriptionRow: View {
    @EnvironmentObject private var theme: Theme
    let subscription: YouTubeSubscription

    @State private var isAddedToFeeds: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = subscription.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholderIcon
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                placeholderIcon
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.primaryText01)
                    .lineLimit(1)

                if !subscription.description.isEmpty {
                    Text(subscription.description)
                        .font(.caption)
                        .foregroundColor(theme.primaryText02)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Add to feeds button
            if isAddedToFeeds {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else {
                Button {
                    addToFeeds()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primaryInteractive01)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.open(subscription.channelURL)
        }
        .onAppear {
            isAddedToFeeds = YouTubeFeedManager.shared.feedExists(withId: subscription.channelID)
        }
    }

    private var placeholderIcon: some View {
        Circle()
            .fill(theme.primaryUi05)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(theme.primaryIcon02)
                    .font(.system(size: 20))
            )
    }

    private func addToFeeds() {
        let feed = YouTubeFeed(
            id: subscription.channelID,
            title: subscription.title,
            author: subscription.title,
            feedDescription: subscription.description,
            thumbnailURL: subscription.thumbnailURL?.absoluteString,
            feedURL: subscription.rssFeedURL.absoluteString,
            channelURL: subscription.channelURL.absoluteString
        )

        YouTubeFeedManager.shared.addFeed(feed)
        Analytics.track(.youTubeSubscriptionAdded)

        withAnimation {
            isAddedToFeeds = true
        }
    }
}

// MARK: - UIKit Wrapper

/// UIViewController that hosts the unified YouTube Hub
final class YouTubeHubViewController: UIHostingController<AnyView> {

    init() {
        let rootView = AnyView(
            YouTubeHubRootView()
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
        view.backgroundColor = .clear
    }
}

// MARK: - Root SwiftUI Wrapper

private struct YouTubeHubRootView: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                YouTubeHubView()
                    .environmentObject(theme)
            }
            .tint(theme.primaryInteractive01)
        } else {
            NavigationView {
                YouTubeHubView()
                    .environmentObject(theme)
            }
            .navigationViewStyle(.stack)
            .tint(theme.primaryInteractive01)
        }
    }
}
