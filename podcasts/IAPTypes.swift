import Foundation

enum IAPProductID: String {
    case yearly = "com.pocketcasts.plus.yearly"
    case monthly = "com.pocketcasts.plus.monthly"
    case patronYearly = "com.pocketcasts.patron_yearly"
    case patronMonthly = "com.pocketcasts.patron_monthly"
    case yearlyReferral = "com.pocketcasts.plus.yearly.referral"

    var renewalPrompt: String {
        switch self {
        case .yearly, .patronYearly, .yearlyReferral:
            return L10n.accountPaymentRenewsYearly
        case .monthly, .patronMonthly:
            return L10n.accountPaymentRenewsMonthly
        }
    }

    var isYearlyProduct: Bool {
        switch self {
        case .yearly, .yearlyReferral, .patronYearly:
            return true
        default:
            return false
        }
    }
}

enum IAPPromotionID: String {
    case referall = "com.pocketcasts.plus.yearly.referral.promo"
}

enum IAPOfferType: String {
    case freeTrial = "free_trial"
    case introOffer = "intro_offer"
    case referral = "referral"
    case winback = "winback"
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

enum PlanFrequency: String {
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

struct IAPDiscountInfo {
    let identifier: String
    let uuid: UUID
    let timestamp: Int
    let key: String
    let signature: String
}
