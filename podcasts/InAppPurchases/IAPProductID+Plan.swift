import PocketCastsServer

extension IAPProductID {
    var subscriptionTier: SubscriptionTier {
        switch self {
        case .monthly, .yearly, .yearlyReferral:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var plan: Plan {
        switch self {
        case .monthly, .yearly, .yearlyReferral:
            return .plus
        case .patronYearly, .patronMonthly:
            return .patron
        }
    }

    var frequency: PlanFrequency {
        switch self {
        case .monthly, .patronMonthly:
            return .monthly
        case .yearly, .patronYearly, .yearlyReferral:
            return .yearly
        }
    }

    var productInfo: ProductInfo {
        .init(plan: plan, frequency: frequency)
    }
}
