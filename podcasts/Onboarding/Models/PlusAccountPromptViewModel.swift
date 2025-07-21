import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil

    var source: PlusUpgradeViewSource = .unknown

    let subscription: UserInfo.Subscription? = .init()

    lazy var products: [PlusProductPricingInfo] = {
        let productsToDisplay: [IAPProductID] = {
            return subscription?.tier == .patron ? [.patronYearly] : [.yearly, .patronYearly]
        }()

        return productsToDisplay.compactMap { product in
            pricingInfo.products.first(where: { $0.identifier == product })
        }
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init(purchaseHandler: IAPHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        // Load prices on init
        loadPrices()

        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.expandViewController()
        }
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

    /// Returns the label that should be displayed on an upgrade button
    func upgradeLabel(for product: PlusProductPricingInfo) -> String {
        let plan = product.identifier.plan
        let expiringPlus = subscription?.isExpiring(.plus) == true

        switch plan {
        case .patron:
            return {
                // Show the renew your sub title
                if subscription?.isExpiring(.patron) == true {
                    return L10n.renewSubscription
                }

                // If the user has an expiring plus subscription show the 'Upgrade Account' title
                return expiringPlus ? L10n.upgradeAccount : L10n.patronSubscribeTo
            }()

        case .plus:
            // Show 'Renew Sub' title if it's expiring
            return {
                if expiringPlus {
                    return L10n.renewSubscription
                }
                if product.offer?.type == .freeTrial {
                    return L10n.startFreeTrial
                }
                return L10n.plusSubscribeTo
            }()
        }
    }

    func showModal(for product: PlusProductPricingInfo? = nil) {
        guard let parentController, let product else { return }

        let context: OnboardingFlow.Context? = ["product": ProductInfo(plan: product.identifier.plan, frequency: .yearly)]
        let controller = OnboardingFlow.shared.begin(flow: .plusAccountUpgrade, in: parentController, source: source, context: context)
        let sizeCategory = UIApplication.shared.preferredContentSizeCategory
        let isAccessibility = sizeCategory.isAccessibilityCategory

        if let sheetPresentationController = controller.sheetPresentationController {
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.detents = isAccessibility ? [.large()] : UIScreen.isSmallScreen ? [.large()] : [.medium()]
        }
        parentController.presentFromRootController(controller, animated: true)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }

    private func expandViewController() {
        let sizeCategory = UIApplication.shared.preferredContentSizeCategory
        let isAccessibility = sizeCategory.isAccessibilityCategory
        if let sheet = parentController?.presentedViewController?.sheetPresentationController {
            sheet.detents = isAccessibility ? [.large()] : [.medium()]
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = isAccessibility ? .large : .medium
            }
        }
    }
}
