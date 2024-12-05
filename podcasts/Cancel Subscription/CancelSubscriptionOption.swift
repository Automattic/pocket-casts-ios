enum CancelSubscriptionOption: CaseIterable, Hashable, Identifiable {
    static var allCases: [CancelSubscriptionOption] = [.promotion(price: ""), .availablePlans, .help]

    case promotion(price: String)
    case availablePlans
    case help

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .promotion:
            return L10n.cancelSubscriptionPromotionTitle
        case .availablePlans:
            return L10n.cancelSubscriptionNewPlanTitle
        case .help:
            return L10n.cancelSubscriptionHelpTitle
        }
    }

    var subtitle: String {
        switch self {
        case .promotion(let price):
            return L10n.cancelSubscriptionPromotionDescription(price)
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
}
