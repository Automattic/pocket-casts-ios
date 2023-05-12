import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil
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

        let flow: OnboardingFlow.Flow = product?.identifier.subscriptionType == .patron ? .patronAccountUpgrade : .plusAccountUpgrade
        let controller = OnboardingFlow.shared.begin(flow: flow, in: parentController, source: source.rawValue)

        parentController.present(controller, animated: true)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }
}
