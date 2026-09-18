import PocketCastsServer
import PocketCastsUtils
import SwiftUI

/// The What's New feed: every message published for this user, most recently published first.
struct WhatsNewFeedView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: WhatsNewFeedViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    Button {
                        viewModel.select(item)
                    } label: {
                        WhatsNewFeedRow(item: item)
                    }
                    .buttonStyle(WhatsNewFeedRowButtonStyle())

                    if item.id != viewModel.items.last?.id {
                        Rectangle()
                            .fill(theme.primaryUi05)
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .refreshable { await viewModel.refresh() }
        .overlay {
            if viewModel.items.isEmpty {
                WhatsNewFeedUnavailableView(state: viewModel.state) {
                    Task { await viewModel.retry() }
                }
            }
        }
        .background(theme.primaryUi02.ignoresSafeArea())
        .task { await viewModel.load() }
    }
}

/// What the feed shows while it has no rows: progress, an empty feed, or a failure to retry.
private struct WhatsNewFeedUnavailableView: View {
    @EnvironmentObject private var theme: Theme

    let state: WhatsNewFeedViewModel.State
    let retry: () -> Void

    var body: some View {
        content
            .foregroundStyle(theme.primaryText01, theme.primaryText02)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ContentUnavailableView {
                ProgressView()
            }
        case .loaded:
            ContentUnavailableView(L10n.whatsNewFeedEmptyTitle,
                                   systemImage: "envelope",
                                   description: Text(L10n.whatsNewFeedEmptyDescription))
        case .failed:
            ContentUnavailableView {
                Label(L10n.whatsNewFeedUnableToLoad, systemImage: "wifi.exclamationmark")
            } description: {
                Text(L10n.checkInternetConnection)
            } actions: {
                Button(L10n.tryAgain, action: retry)
                    .foregroundStyle(theme.primaryInteractive01)
            }
        }
    }
}

private struct WhatsNewFeedRow: View {
    @EnvironmentObject private var theme: Theme
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 56
    @ScaledMetric(relativeTo: .caption2) private var unreadIndicatorSize: CGFloat = 8

    let item: WhatsNewFeedItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            WhatsNewFeedIconView(type: item.type)
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 12) {
                    Text(item.label.localizedUppercase)
                        .font(size: 11, style: .caption2, weight: .semibold)
                        .tracking(0.33)
                        .foregroundStyle(theme.primaryText02)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(WhatsNewFeedDateFormatter.string(from: item.publishedAt))
                        .font(size: 11, style: .caption2, weight: .semibold)
                        .foregroundStyle(theme.primaryText02)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Circle()
                        .fill(theme.support05)
                        .frame(width: unreadIndicatorSize, height: unreadIndicatorSize)
                        .opacity(item.isUnread ? 1 : 0)
                }

                Text(item.title)
                    .font(size: 15, style: .subheadline, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// The icon the message's type picks, which the client owns: authors choose a type, not a thumbnail.
private struct WhatsNewFeedIconView: View {
    let type: WhatsNewMessageType

    var body: some View {
        ZStack {
            LinearGradient(colors: type.iconGradient, startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: type.iconSymbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

private struct WhatsNewFeedRowButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? theme.primaryUi02Active : theme.primaryUi02)
    }
}

private enum WhatsNewFeedDateFormatter {
    static func string(from date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return L10n.today
        }
        return (date.isCurrentYear() ? monthDay : monthDayYear).string(from: date)
    }

    private static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    private static let monthDayYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy")
        return formatter
    }()
}

// MARK: - Previews

private extension WhatsNewFeedViewModel {
    /// The mock catalog with everything but the two most recent messages already read.
    static var mock: WhatsNewFeedViewModel {
        let messages = WhatsNewCatalog.mock.messages
        return WhatsNewFeedViewModel(messages: messages, readMessageIDs: Set(messages.dropFirst(2).map(\.id)))
    }
}

#Preview("Feed in a navigation controller") {
    PCNavigationController(rootViewController: WhatsNewFeedViewController(viewModel: .mock))
}

#Preview("Loading") {
    WhatsNewFeedUnavailableView(state: .loading) {}
        .previewFollowingAppearance()
}

#Preview("Empty") {
    WhatsNewFeedView(viewModel: WhatsNewFeedViewModel(messages: []))
        .previewFollowingAppearance()
}

#Preview("Failed") {
    WhatsNewFeedUnavailableView(state: .failed) {}
        .previewFollowingAppearance()
}
