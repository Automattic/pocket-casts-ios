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

    private var contentSizeObserver: NSObjectProtocol?

    deinit {
        if let contentSizeObserver {
            NotificationCenter.default.removeObserver(contentSizeObserver)
        }
    }

    override init(purchaseHandler: IAPHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        // Load prices on init
        loadPrices()

        contentSizeObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.expandViewController()
        }
    }

    @MainActor
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

    @MainActor
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
