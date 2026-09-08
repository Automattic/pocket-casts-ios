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
        .background(theme.primaryUi02.ignoresSafeArea())
    }
}

private struct WhatsNewFeedRow: View {
    @EnvironmentObject private var theme: Theme
    @ScaledMetric(relativeTo: .largeTitle) private var artworkSize: CGFloat = 56
    @ScaledMetric(relativeTo: .caption2) private var unreadIndicatorSize: CGFloat = 8

    let item: WhatsNewFeedItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            WhatsNewFeedArtworkView(item: item)
                .frame(width: artworkSize, height: artworkSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 12) {
                    if let label = item.label {
                        Text(label.localizedUppercase)
                            .font(size: 11, style: .caption2, weight: .semibold)
                            .tracking(0.33)
                            .foregroundStyle(theme.primaryText02)
                            .lineLimit(1)
                    }

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

/// The artwork the CDN published for a message, over a fallback the message's type picks.
private struct WhatsNewFeedArtworkView: View {
    let item: WhatsNewFeedItem

    var body: some View {
        ZStack {
            LinearGradient(colors: item.type.artworkGradient, startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: item.type.artworkSymbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)

            if let imageURL = item.imageURL {
                AsyncImageView(url: imageURL, cache: ImageManager.sharedManager.discoverCache)
            }
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

private extension WhatsNewMessageType {
    var artworkGradient: [Color] {
        switch self {
        case .tip:
            [UIColor(hex: "#03A9F4").color, UIColor(hex: "#50D0F1").color]
        case .newFeature:
            [UIColor(hex: "#F43769").color, UIColor(hex: "#FB5246").color]
        case .research:
            [UIColor(hex: "#6B59C7").color, UIColor(hex: "#BC4E7B").color]
        case .announcement:
            [UIColor(hex: "#C9522E").color, UIColor(hex: "#B82E3C").color]
        case .knownIssue:
            [UIColor(hex: "#FF9D3B").color, UIColor(hex: "#EB6F4F").color]
        }
    }

    var artworkSymbolName: String {
        switch self {
        case .tip: "arrow.up.arrow.down"
        case .newFeature: "list.bullet"
        case .research: "doc.text"
        case .announcement: "heart"
        case .knownIssue: "exclamationmark.triangle"
        }
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

struct WhatsNewFeedView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewFeedView(viewModel: .mock)
            .previewWithAllThemes()
    }
}
