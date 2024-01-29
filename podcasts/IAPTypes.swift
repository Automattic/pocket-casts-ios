import Foundation

enum IAPProductID: String {
    case yearly = "com.pocketcasts.plus.yearly"
    case monthly = "com.pocketcasts.plus.monthly"
    case patronYearly = "com.pocketcasts.patron_yearly"
    case patronMonthly = "com.pocketcasts.patron_monthly"

    var renewalPrompt: String {
        switch self {
        case .yearly, .patronYearly:
            return L10n.accountPaymentRenewsYearly
        case .monthly, .patronMonthly:
            return L10n.accountPaymentRenewsMonthly
        }
    }
}

enum Plan {
    case plus, patron

    var products: [IAPProductID] {
        return [yearly, monthly]
    }

    var yearly: IAPProductID {
        switch self {
        case .plus:
            return .yearly
        case .patron:
            return .patronYearly
        }
    }

    var monthly: IAPProductID {
        switch self {
        case .plus:
            return .monthly
        case .patron:
            return .patronMonthly
        }
    }
}

enum PlanFrequency {
    case yearly, monthly

    var description: String {
        switch self {
        case .yearly: return L10n.year
        case .monthly: return L10n.month
        }
    }
}

struct ProductInfo {
    let plan: Plan
    let frequency: PlanFrequency
}
