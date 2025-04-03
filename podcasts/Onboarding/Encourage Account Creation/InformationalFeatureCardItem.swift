import SwiftUI

enum InformationalFeatureCardItem: String, CaseIterable, Identifiable, HorizontalCarouselItemRepresentable {
    case sync
    case backups
    case recommendation

    var title: String {
        switch self {
        case .sync:
            return "Sync across devices"
        case .backups:
            return "Reliable backups"
        case .recommendation:
            return "Personalized recommendations"
        }
    }

    var text: String {
        switch self {
        case .sync:
            return "Sync your progress, and shows across all your devices."
        case .backups:
            return "Your library and preferences are securely saved."
        case .recommendation:
            return "Get tailored podcast suggestions based on your listening habits."
        }
    }

    var image: String {
        return "informational_card_\(rawValue.lowerSnakeCased())"
    }

    var backgroundColor: Color {
        AppTheme.color(for: .primaryUi02Active)
    }

    var titleColor: Color {
        AppTheme.color(for: .primaryText01)
    }

    var titleSize: CGFloat {
        18.0
    }

    var textColor: Color {
        AppTheme.color(for: .primaryText02)
    }

    var textSize: CGFloat {
        14.0
    }
}
