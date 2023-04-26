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
        var products: [Constants.IapProducts]
        if FeatureFlag.patron.enabled {
            products = [.yearly, .monthly, .patronYearly, .patronMonthly]
        } else {
            products = [.yearly, .monthly]
        }
        var pricing: [PlusProductPricingInfo] = []

        for product in products {
            let price = purchaseHandler.getPriceWithFrequency(for: product) ?? ""
            let rawPrice = purchaseHandler.getPriceForIdentifier(identifier: product.rawValue)
            let trial = purchaseHandler.localizedFreeTrialDuration(product)

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              rawPrice: rawPrice,
                                              freeTrialDuration: trial)
            pricing.append(info)
        }

        // Sort any products with free trials to the top of the list
        pricing.sort { $0.freeTrialDuration != nil && $1.freeTrialDuration == nil }

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
        let freeTrialDuration: String?

        var id: String { identifier.rawValue }
    }

    enum PriceAvailablity {
        case unknown, available, loading, failed
    }

    enum DisplayPrice {
        case yearly, monthly
    }
}

// MARK: - Price Loading
extension PlusPricingInfoModel {
    func loadPrices(_ completion: @escaping () -> Void) {
        if purchaseHandler.hasLoadedProducts {
            priceAvailability = .available
            pricingInfo = Self.getPricingInfo(from: self.purchaseHandler)
            completion()
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
            completion()
        }

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsFailed, object: nil, queue: .main) { _ in
            self.priceAvailability = .failed
            completion()
        }

        purchaseHandler.requestProductInfo()
    }
}
