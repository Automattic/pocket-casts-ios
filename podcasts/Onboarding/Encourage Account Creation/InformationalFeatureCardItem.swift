import SwiftUI

enum InformationalFeatureCardItem: String, CaseIterable, Identifiable, HorizontalCarouselItemRepresentable {
    case sync
    case backups
    case recommendation

    var title: String {
        switch self {
        case .sync:
            return L10n.eacInformationalCardSyncTitle
        case .backups:
            return L10n.eacInformationalCardBackupsTitle
        case .recommendation:
            return L10n.eacInformationalCardRecommendationTitle
        }
    }

    var text: String {
        switch self {
        case .sync:
            return L10n.eacInformationalCardSyncDescription
        case .backups:
            return L10n.eacInformationalCardBackupsDescription
        case .recommendation:
            return L10n.eacInformationalCardRecommendationDescription
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
