import SwiftUI

/// Shown when a Discover section or screen fails to load, giving the user a way to try
/// again instead of leaving them staring at a spinner or a silently empty gap.
struct DiscoverRetryView: View {

    enum Style {
        /// Compact, left-aligned presentation used in place of a single Home/Discover row.
        case row
        /// Full-screen presentation used for standalone Discover screens.
        case fullScreen
    }

    let title: String
    let style: Style
    let retry: () async -> Void

    init(title: String = L10n.tvDiscoverFailedToLoadTitle, style: Style, retry: @escaping () async -> Void) {
        self.title = title
        self.style = style
        self.retry = retry
    }

    var body: some View {
        switch style {
        case .row:
            HStack(spacing: 24) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.pcTextSecondary)
                retryButton
                Spacer()
            }
            .padding(.vertical, 24)
        case .fullScreen:
            ContentUnavailableView {
                Text(title)
            } description: {
                Text(L10n.tvDiscoverFailedToLoadSubtitle)
            } actions: {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button {
            Task { await retry() }
        } label: {
            Label(L10n.retry, systemImage: "arrow.clockwise")
        }
    }
}
