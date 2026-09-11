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

    /// The symbol at the centre of the feed icon, which stands in for the glyph the design picks.
    var iconSymbolName: String {
        switch self {
        case .newFeature: "list.bullet"
        case .tip: "arrow.up.arrow.down"
        case .announcement: "heart"
        case .knownIssue: "exclamationmark.triangle"
        case .research: "doc.text"
        }
    }

    /// The colours the feed icon is drawn on.
    var iconGradient: [Color] {
        switch self {
        case .newFeature:
            [UIColor(hex: "#F43769").color, UIColor(hex: "#FB5246").color]
        case .tip:
            [UIColor(hex: "#03A9F4").color, UIColor(hex: "#50D0F1").color]
        case .announcement:
            [UIColor(hex: "#C9522E").color, UIColor(hex: "#B82E3C").color]
        case .knownIssue:
            [UIColor(hex: "#FF9D3B").color, UIColor(hex: "#EB6F4F").color]
        case .research:
            [UIColor(hex: "#6B59C7").color, UIColor(hex: "#BC4E7B").color]
        }
    }
}
