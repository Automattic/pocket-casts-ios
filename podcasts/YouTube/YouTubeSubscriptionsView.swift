import SwiftUI
import PocketCastsUtils

// MARK: - YouTubeSubscriptionsView

/// Shows the authenticated user's YouTube channel subscriptions
struct YouTubeSubscriptionsView: View {

    @EnvironmentObject private var theme: Theme
    @ObservedObject private var authManager = YouTubePlaylistAuthManager.shared
    @StateObject private var viewModel = YouTubeSubscriptionsViewModel()

    @State private var showConnectSheet = false

    /// Called when user wants to subscribe to a channel as a feed
    var onSubscribeToFeed: ((YouTubeSubscription) -> Void)?

    var body: some View {
        Group {
            if authManager.isSignedIn {
                subscriptionsContent
            } else {
                notConnectedPlaceholder
            }
        }
        .navigationTitle("YouTube Subscriptions")
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
                viewModel.loadSubscriptions()
            }
            .environmentObject(theme)
        }
        .onAppear {
            if authManager.isSignedIn && viewModel.loadState == .idle {
                viewModel.loadSubscriptions()
            }
        }
        .onChange(of: authManager.isSignedIn) { isSignedIn in
            if isSignedIn {
                viewModel.loadSubscriptions()
            } else {
                viewModel.subscriptions = []
                viewModel.loadState = .idle
            }
        }
    }

    // MARK: - Subscriptions Content

    @ViewBuilder
    private var subscriptionsContent: some View {
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
            emptyPlaceholder(
                icon: "person.2",
                title: "No Subscriptions Found",
                message: "You're not subscribed to any YouTube channels yet."
            )

        case .loaded:
            List(viewModel.subscriptions) { subscription in
                YouTubeSubscriptionRow(
                    subscription: subscription,
                    onSubscribeToFeed: onSubscribeToFeed
                )
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
            Image(systemName: "person.2.circle")
                .font(.system(size: 52))
                .foregroundColor(theme.primaryInteractive01)
            Text("YouTube Not Connected")
                .font(.title2.bold())
                .foregroundColor(theme.primaryText01)
            Text("Connect your Google account to see your YouTube subscriptions.")
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

// MARK: - YouTubeSubscriptionRow

private struct YouTubeSubscriptionRow: View {
    @EnvironmentObject private var theme: Theme
    let subscription: YouTubeSubscription
    var onSubscribeToFeed: ((YouTubeSubscription) -> Void)?

    @State private var isSubscribed: Bool = false
    @State private var showAddedFeedback: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 48, height: 48)
                .clipShape(Circle())

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

            // Add to Pocket Casts button or checkmark if already added
            if isSubscribed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else if let onSubscribe = onSubscribeToFeed {
                Button {
                    onSubscribe(subscription)
                    withAnimation {
                        isSubscribed = true
                        showAddedFeedback = true
                    }
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
            // Open channel in YouTube/Safari
            UIApplication.shared.open(subscription.channelURL)
        }
        .onAppear {
            // Check if already subscribed in Pocket Casts
            isSubscribed = YouTubeFeedManager.shared.feedExists(withId: subscription.channelID)
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = subscription.thumbnailURL {
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
        Circle()
            .fill(theme.primaryUi05)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryIcon02)
            )
    }
}
