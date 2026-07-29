import Foundation

/// The four emoji-face rating levels for chat feedback.
enum ChatFeedbackRating: String, CaseIterable, Identifiable {
    case love
    case happy
    case neutral
    case unhappy

    var id: String { rawValue }

    /// Whether this is a positive rating (love/happy) or negative (neutral/unhappy).
    var isPositive: Bool {
        switch self {
        case .love, .happy: return true
        case .neutral, .unhappy: return false
        }
    }

    /// Emoji character for display.
    var emoji: String {
        switch self {
        case .love: return "\u{1F60D}"
        case .happy: return "\u{1F642}"
        case .neutral: return "\u{1F610}"
        case .unhappy: return "\u{1F641}"
        }
    }
}

/// Multi-selectable reason chips shown after a negative rating.
enum ChatFeedbackReason: String, CaseIterable, Identifiable {
    case inaccurate
    case notHelpful
    case tooVague
    case tooSlow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inaccurate: return L10n.chatFeedbackReasonInaccurate
        case .notHelpful: return L10n.chatFeedbackReasonNotHelpful
        case .tooVague: return L10n.chatFeedbackReasonTooVague
        case .tooSlow: return L10n.chatFeedbackReasonTooSlow
        }
    }
}

/// The payload captured when the user submits feedback.
struct ChatFeedbackResult {
    let rating: ChatFeedbackRating
    let reasons: Set<ChatFeedbackReason>
    let additionalComment: String
}
