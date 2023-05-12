import UIKit

class PlusAccountPromptViewModel: PlusPurchaseModel {
    var source: Source = .unknown

    let subscription: UserInfo.Subscription? = .init()

    lazy var products: [PlusProductPricingInfo] = {
        let productsToDisplay: [Constants.IapProducts] = {
            guard FeatureFlag.patron.enabled else {
                return [.yearly]
            }

            return subscription?.type == .patron ? [.patronYearly] : [.yearly, .patronYearly]
        }()

        return productsToDisplay.compactMap { product in
            pricingInfo.products.first(where: { $0.identifier == product })
        }
    }()

    override init(purchaseHandler: IapHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        // Load prices on init
        loadPrices()
    }

    func upgradeTapped(with product: PlusProductPricingInfo? = nil) {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal(for: product)
            case .failed:
                self.showError()
            default:
                break
            }
        }
    }

    enum Source: String {
        case unknown
        case accountDetails = "account_details"
        case plusDetails = "plus_details"
    }
}

private extension PlusAccountPromptViewModel {
    func showModal(for product: PlusProductPricingInfo? = nil) {
        guard let parentController else { return }

        guard FeatureFlag.patron.enabled else {
            let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: parentController, source: source.rawValue)
            controller.presentModally(in: parentController)
            return
        }

        // If the user already has a subscription and we're prompting them to renew
        // Then go straight to purchasing
        if let product = product?.identifier, subscription?.isExpiring(product.subscriptionType) == true {
            purchase(product: product)
            return
        }

        // Set the initial product to display on the upsell
        let context: OnboardingFlow.Context? = product.map {
            ["product": Constants.ProductInfo(plan: $0.identifier.plan, frequency: .yearly)]
        }

        let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: parentController, source: source.rawValue, context: context)

        parentController.present(controller, animated: true)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }
}
