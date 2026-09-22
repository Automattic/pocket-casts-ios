import PocketCastsServer
import SwiftUI

/// How the feed presents each kind of message.
///
/// The catalog publishes neither a label nor a thumbnail: authors pick a type, and every client
/// names and illustrates the types it knows itself. A message picks up the reader's language and
/// this app's iconography rather than the author's.
extension WhatsNewMessageType {
    /// What the feed calls this kind of message.
    var categoryLabel: String {
        switch self {
        case .newFeature: L10n.whatsNewCategoryNewFeature
        case .tip: L10n.whatsNewCategoryTip
        case .announcement: L10n.whatsNewCategoryAnnouncement
        case .knownIssue: L10n.whatsNewCategoryKnownIssue
        case .research: L10n.whatsNewCategoryResearch
        }
    }

    /// The glyph at the centre of the feed icon.
    var icon: Image {
        switch self {
        case .newFeature: Image("whatsnew_feed_new_feature")
        case .tip: Image("whatsnew_feed_tip")
        case .announcement: Image("whatsnew_feed_announcement")
        case .knownIssue: Image(systemName: "exclamationmark.triangle")
        case .research: Image("transcript")
        }
    }

    /// The gradient the feed icon is drawn on.
    func iconGradient(theme: Theme) -> LinearGradient {
        switch self {
        case .newFeature:
            LinearGradient(colors: [theme.gradient05A, theme.gradient05E], startPoint: UnitPoint(x: 0, y: 0.4), endPoint: UnitPoint(x: 1, y: 0.6))
        case .tip:
            LinearGradient(colors: [theme.gradient03A, theme.gradient03E], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .announcement:
            LinearGradient(colors: [theme.gradient02A, theme.gradient02E], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .knownIssue:
            LinearGradient(colors: [UIColor(hex: "#FF9D3B").color, UIColor(hex: "#EB6F4F").color], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .research:
            LinearGradient(colors: [theme.gradient04A, theme.gradient04E], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
