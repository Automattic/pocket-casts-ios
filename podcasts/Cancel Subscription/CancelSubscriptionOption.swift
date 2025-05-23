import PocketCastsServer

enum CancelSubscriptionOption: CaseIterable, Hashable, Identifiable {
    static var allCases: [CancelSubscriptionOption] = [.promotion(price: "", frequency: .none), .availablePlans, .help]

    case promotion(price: String, frequency: SubscriptionFrequency)
    case availablePlans
    case help

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .promotion(_, let frequency):
            if frequency == .monthly {
                return L10n.cancelSubscriptionPromotionTitle
            } else {
                return L10n.cancelSubscriptionYearlyPromotionTitle
            }
        case .availablePlans:
            return L10n.cancelSubscriptionNewPlanTitle
        case .help:
            return L10n.cancelSubscriptionHelpTitle
        }
    }

    var subtitle: String {
        switch self {
        case .promotion(let price, let frequency):
            if frequency == .monthly {
                return L10n.cancelSubscriptionPromotionDescriptionMonthly(price)
            } else {
                return L10n.cancelSubscriptionPromotionDescriptionYearly(price)
            }
        case .availablePlans:
            return L10n.cancelSubscriptionNewPlanDescription
        case .help:
            return L10n.cancelSubscriptionHelpDescription
        }
    }

    var icon: String {
        switch self {
        case .promotion:
            return "cs-heart"
        case .availablePlans:
            return "cs-skipbackward"
        case .help:
            return "cs-help"
        }
    }

    var analyticsRow: String {
        switch self {
        case .promotion:
            return "claim_offer"
        case .availablePlans:
            return "available_plans"
        case .help:
            return "help_and_feedback"
        }
    }
}
