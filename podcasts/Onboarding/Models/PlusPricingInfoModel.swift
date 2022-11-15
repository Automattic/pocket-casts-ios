import UIKit
import PocketCastsServer

/// A parent model that allows a view to present pricing information
class PlusPricingInfoModel: ObservableObject {
    // Allow injection of the IapHelper
    let purchaseHandler: IapHelper

    // Allow our views to get the necessary pricing information
    let pricingInfo: PlusPricingInfo

    /// Determines whether prices are available
    @Published var priceAvailability: PriceAvailablity

    init(purchaseHandler: IapHelper = .shared) {
        self.purchaseHandler = purchaseHandler
        self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
        self.priceAvailability = purchaseHandler.hasLoadedProducts ? .available : .unknown
    }

    private static func getPricingInfo(from purchaseHandler: IapHelper) -> PlusPricingInfo {
        let products: [Constants.IapProducts] = [.yearly, .monthly]
        var pricing: [PlusProductPricingInfo] = []

        for product in products {
            let price = purchaseHandler.getPriceWithFrequency(for: product) ?? ""
            let trial = purchaseHandler.localizedFreeTrialDuration(product)

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              freeTrialDuration: trial)
            pricing.append(info)
        }

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
        let freeTrialDuration: String?

        var id: String { identifier.rawValue }
    }

    enum PriceAvailablity {
        case unknown, available, loading, failed
    }
}

// MARK: - Price Loading
extension PlusPricingInfoModel {
    func loadPrices(_ completion: @escaping () -> Void) {
        if purchaseHandler.hasLoadedProducts {
            priceAvailability = .available
            completion()
            return
        }

        priceAvailability = .loading

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: .main) { _ in

            self.priceAvailability = .available
            completion()
        }

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsFailed, object: nil, queue: .main) { _ in
            self.priceAvailability = .failed
            completion()
        }

        purchaseHandler.requestProductInfo()
    }
}
