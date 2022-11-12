import UIKit
import SwiftUI
import PocketCastsServer

class PlusPurchaseCoordinator: ObservableObject {
    var navigationController: UINavigationController? = nil

    // Keep track of our internal state, and pass this to our view
    @Published var state: PurchaseState = .none

    // Allow our views to get the necessary pricing information
    let pricingInfo: PlusPricingInfo

    private var purchasedProduct: Constants.IapProducts?

    init() {
        self.pricingInfo = Self.getPricingInfo()
    }

    // MARK: - Triggers the purchase process
    func purchase(product: Constants.IapProducts) {
        self.purchasedProduct = product
        updateState(.purchasing)

        // TODO: Add a real call
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.updateState(.failed)
        }
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
        let firstFreeTrial: IapHelper.FreeTrialDetails? = IapHelper.shared.getFirstFreeTrialDetails()
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
            let price = IapHelper.shared.getPriceWithFrequency(for: product)
            let trial = IapHelper.shared.localizedFreeTrialDuration(product)

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              freeTrialDuration: trial)
            pricing.append(info)
        }

        return PlusPricingInfo(products: pricing)
    }

    private func updateState(_ state: PurchaseState) {
        self.state = state
        self.objectWillChange.send()
    }
}
