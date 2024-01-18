import UIKit
import PocketCastsServer

/// A parent model that allows a view to present pricing information
class PlusPricingInfoModel: ObservableObject {
    // Allow injection of the IapHelper
    let purchaseHandler: IapHelper

    // Allow our views to get the necessary pricing information
    @Published var pricingInfo: PlusPricingInfo

    /// Determines whether prices are available
    @Published var priceAvailability: PriceAvailablity

    init(purchaseHandler: IapHelper = .shared) {
        self.purchaseHandler = purchaseHandler
        self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
        self.priceAvailability = purchaseHandler.hasLoadedProducts ? .available : .unknown
    }

    private static func getPricingInfo(from purchaseHandler: IapHelper) -> PlusPricingInfo {
        let products: [Constants.IapProducts] = [.yearly, .monthly, .patronYearly, .patronMonthly]

        var pricing: [PlusProductPricingInfo] = []

        for product in products {
            let price = purchaseHandler.getPriceWithFrequency(for: product) ?? ""
            let rawPrice = purchaseHandler.getPriceForIdentifier(identifier: product.rawValue)
            var offer: ProductOfferInfo?
            if let duration = purchaseHandler.localizedFreeTrialDuration(product),
               let type = purchaseHandler.offerType(product),
               let price = purchaseHandler.localizedOfferPrice(product) {
                offer = ProductOfferInfo(type: type, duration: duration, price: price, rawPrice: rawPrice)
            }

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              rawPrice: rawPrice,
                                              offer: offer)
            pricing.append(info)
        }

        // Sort any products with free trials to the top of the list
        pricing.sort { $0.offer != nil && $1.offer == nil }

        let hasFreeTrial = purchaseHandler.getFirstFreeTrialDetails() != nil
        return PlusPricingInfo(products: pricing, hasFreeTrial: hasFreeTrial)
    }

    // A simple struct to keep track of the product and pricing information the view needs
    struct PlusPricingInfo {
        let products: [PlusProductPricingInfo]
        let hasFreeTrial: Bool
    }

    struct PlusProductPricingInfo: Identifiable {
        let identifier: Constants.IapProducts
        let price: String
        let rawPrice: String
        let offer: ProductOfferInfo?

        var id: String { identifier.rawValue }
    }

    enum ProductOfferType {
        case freeTrial
        case discount
        case unknown
    }

    struct ProductOfferInfo {
        let type: ProductOfferType
        let duration: String
        let price: String
        let rawPrice: String

        var title: String {
            switch type {
            case .freeTrial:
                return L10n.plusStartMyFreeTrial
            case .discount:
                return "First year at half price!"
            case .unknown:
                return "Special offer"
            }
        }

        var description: String {
            switch type {
            case .freeTrial:
                return L10n.plusFreeMembershipFormat(duration)
            case .discount:
                return "First year at \(price)"
            case .unknown:
                return "Open to see it"
            }
        }

        var comparation: String {
            switch type {
            case .freeTrial:
                return L10n.plusStartTrialDurationPrice(duration, rawPrice)
            case .discount:
                return "First year at \(price) then \(rawPrice)"
            case .unknown:
                return "Open to see it"
            }
        }

    }

    enum PriceAvailablity {
        case unknown, available, loading, failed
    }
}

// MARK: - Price Loading
extension PlusPricingInfoModel {
    func loadPrices(_ completion: (() -> Void)? = nil) {
        if purchaseHandler.hasLoadedProducts {
            priceAvailability = .available
            pricingInfo = Self.getPricingInfo(from: self.purchaseHandler)
            completion?()
            return
        }

        priceAvailability = .loading

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: .main) { [weak self] _ in
            guard let self else {
                return
            }

            self.priceAvailability = .available
            self.pricingInfo = Self.getPricingInfo(from: self.purchaseHandler)
            completion?()
        }

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsFailed, object: nil, queue: .main) { _ in
            self.priceAvailability = .failed
            completion?()
        }

        purchaseHandler.requestProductInfo()
    }
}
