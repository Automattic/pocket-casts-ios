import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionViewModel: PlusPurchaseModel {
    let navigationController: UINavigationController

    var isEligibleForOffer: Bool {
        purchaseHandler.isEligibleForOffer
    }

    private var lastPurchasedProductID: IAPProductID?

    @Published var currentPricingProduct: PlusPricingInfoModel.PlusProductPricingInfo?
    @State var currentProductAvailability: CurrentProductAvailability = .idle

    init(purchaseHandler: IAPHelper = .shared, navigationController: UINavigationController) {
        self.navigationController = navigationController

        super.init(purchaseHandler: purchaseHandler)

        self.loadPrices()
    }

    override func didAppear() {
        //TODO: Implement analytics
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        //TODO: Implement analytics
    }

    override func handleNext() {
        if SubscriptionHelper.activeTier == .patron {
            let controller = PatronWelcomeViewModel.make(in: navigationController)
            navigationController.pushViewController(controller, animated: true)
        } else {
            navigationController.dismiss(animated: true)
        }
    }

    enum CurrentProductAvailability {
        case idle
        case loading
        case available
        case unavailable
    }
}

// IAP
extension CancelSubscriptionViewModel {
    func monthlyPrice() -> String? {
        switch SubscriptionHelper.activeTier {
        case .plus:
            return pricingInfo.products.first { $0.identifier == .monthly }?.rawPrice
        case .patron:
            return pricingInfo.products.first { $0.identifier == .patronMonthly }?.rawPrice
        case .none:
            return nil
        }
    }

    func loadCurrentProduct() async {
        if currentProductAvailability == .loading { return }

        currentProductAvailability = .loading
        if let transaction = await purchaseHandler.findLastSubscriptionPurchased(),
           let productID = IAPProductID(rawValue: transaction.productID) {
            await MainActor.run {
                lastPurchasedProductID = productID
                currentProductAvailability = .available
                currentPricingProduct = pricingInfo.products.first { $0.identifier == productID }
            }
        } else {
            currentProductAvailability = .unavailable
            FileLog.shared.console("[CancelSubscriptionViewModel] Could not find last subscription purchased")
        }
    }

    func purchase(product: PlusPricingInfoModel.PlusProductPricingInfo) {
        currentPricingProduct = product

        if currentPricingProduct?.identifier != lastPurchasedProductID {
            purchase(product: product.identifier)
        }
    }

    func claimOffer() {
        //TODO: Apply one month free
    }
}

// Navigation
extension CancelSubscriptionViewModel {
    func cancelSubscriptionTap() {
        //TODO: Implement analytics
        let viewController = CancelConfirmationViewModel.make(in: navigationController)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showPlans() {
        //TODO: Implement analytics
        let view = CancelSubscriptionPlansView(viewModel: self).setupDefaultEnvironment()
        let controller = OnboardingHostingViewController(rootView: view)
        controller.navBarIsHidden = true
        navigationController.pushViewController(controller, animated: true)
    }

    func showHelp() {
        //TODO: Implement analytics
        let controller = OnlineSupportController()
        navigationController.navigationBar.isHidden = false
        navigationController.pushViewController(controller, animated: true)
    }

    func closePlans() {
        //TODO: Implement analytics
        navigationController.dismiss(animated: true)
    }
}

// Making vew controller
extension CancelSubscriptionViewModel {
    /// Make the view, and allow it to be shown by itself or within another navigation flow
    static func make() -> UIViewController {
        // If we're not being presented within another nav controller then wrap ourselves in one
        let navController = UINavigationController()
        let viewModel = CancelSubscriptionViewModel(navigationController: navController)
        viewModel.parentController = navController

        // Wrap the SwiftUI view in the hosting view controller
        let swiftUIView = CancelSubscriptionView(viewModel: viewModel).setupDefaultEnvironment()

        // Configure the controller
        let controller = OnboardingHostingViewController(rootView: swiftUIView)
        controller.navBarIsHidden = true
        controller.viewModel = viewModel

        // Set the root view of the new nav controller
        navController.setViewControllers([controller], animated: false)
        return navController
    }
}
