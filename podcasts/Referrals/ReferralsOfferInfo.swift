import Foundation

protocol ReferralsOfferInfo {
    var localizedOfferDurationNoun: String { get }
    var localizedOfferDurationAdjective: String { get }
    var localizedPriceAfterOffer: String { get }
}

struct ReferralsOfferInfoMock: ReferralsOfferInfo {

    var localizedOfferDurationNoun: String {
        return "2 Months"
    }

    var localizedOfferDurationAdjective: String {
        return "2-Month"
    }

    var localizedPriceAfterOffer: String {
        return "$39.99 USD"
    }
}

struct ReferralsOfferInfoIAP: ReferralsOfferInfo {

    let productID: IAPProductID

    var localizedOfferDurationNoun: String {
        return IAPHelper.shared.localizedFreeTrialDuration(productID)?.capitalized ?? "N/A"
    }

    var localizedOfferDurationAdjective: String {
        return IAPHelper.shared.localizedFreeTrialDurationAdjective(productID)?.capitalized ?? "N/A"
    }

    var localizedPriceAfterOffer: String {
        return IAPHelper.shared.getPrice(for: productID)
    }
}
