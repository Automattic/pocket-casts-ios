import UIKit
import SwiftUI
import PocketCastsServer

class PlusPurchaseCoordinator: ObservableObject {
    var navigationController: UINavigationController? = nil

    // Allow injection of the IapHelper
    let purchaseHandler: IapHelper

    // Keep track of our internal state, and pass this to our view
    @Published var state: PurchaseState = .none

    // Allow our views to get the necessary pricing information
    let pricingInfo: PlusPricingInfo

    private var purchasedProduct: Constants.IapProducts?

    init(purchaseHandler: IapHelper = .shared) {
        self.purchaseHandler = purchaseHandler
        self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
        addPaymentObservers()
    }

    // MARK: - Triggers the purchase process
    func purchase(product: Constants.IapProducts) {
        guard purchaseHandler.buyProduct(identifier: product.rawValue) else {
            handlePurchaseFailed(error: nil)
            return
        }

        self.purchasedProduct = product
        updateState(.purchasing)
    }

    // Our internal state
    enum PurchaseState {
        case none
        case purchasing
        case successful
        case cancelled
        case failed
    }

    // A simple struct to keep track of the product and pricing information the view needs
    struct PlusPricingInfo {
        let products: [PlusProductPricingInfo]
        let firstFreeTrial: IapHelper.FreeTrialDetails?
        var hasFreeTrial: Bool { firstFreeTrial != nil }
    }

    struct PlusProductPricingInfo: Identifiable {
        let identifier: Constants.IapProducts
        let price: String
        let freeTrialDuration: String?

        var id: String { identifier.rawValue }
    }
}

extension PlusPurchaseCoordinator {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let coordinator = PlusPurchaseCoordinator()
        coordinator.navigationController = navigationController

        let backgroundColor = UIColor(hex: PlusPurchaseModal.Config.backgroundColorHex)
        let modal = PlusPurchaseModal(coordinator: coordinator)
        let controller = MDCSwiftUIWrapper(rootView: modal, backgroundColor: backgroundColor)

        return controller
    }
}

private extension PlusPurchaseCoordinator {
    private static func getPricingInfo() -> PlusPricingInfo {
        let products: [Constants.IapProducts] = [.yearly, .monthly]
        var pricing: [PlusProductPricingInfo] = []

        for product in products {
            let price = purchaseHandler.getPriceWithFrequency(for: product)
            let trial = purchaseHandler.localizedFreeTrialDuration(product)

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              freeTrialDuration: trial)
            pricing.append(info)
        }

        return PlusPricingInfo(products: pricing, firstFreeTrial: purchaseHandler.getFirstFreeTrialDetails())
    }

    private func updateState(_ state: PurchaseState) {
        self.state = state
        self.objectWillChange.send()
    }
}
