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
