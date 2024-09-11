import Foundation

protocol ReferralsOfferInfo {
    var localizedOfferDuration: String { get }
    var localizedPriceAfterOffer: String { get }
}

struct ReferralsOfferInfoMock: ReferralsOfferInfo {

    var localizedOfferDuration: String {
        return "2 Months"
    }

    var localizedPriceAfterOffer: String {
        return "$39.99 USD"
    }
}
