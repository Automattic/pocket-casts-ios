import SwiftUI
import PocketCastsServer

class CancelSubscriptionViewModel: PlusPurchaseModel {
    let navigationController: UINavigationController

    var isEligibleForOffer: Bool {
        purchaseHandler.isEligibleForOffer
    }

    init(purchaseHandler: IAPHelper = .shared, navigationController: UINavigationController) {
        self.navigationController = navigationController

        super.init(purchaseHandler: purchaseHandler)

        self.loadPrices()
    }

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

    func cancelSubscriptionTap() {
        let viewController = CancelConfirmationViewModel.make(in: navigationController)
        navigationController.pushViewController(viewController, animated: true)
    }

    func claimOffer() {
        //TODO: Apply one month free
    }

    func showPlans() {
        //TODO: Show plans
    }

    func showHelp() {
        let controller = OnlineSupportController()
        navigationController.navigationBar.isHidden = false
        navigationController.pushViewController(controller, animated: true)
    }

    override func didAppear() {
        //TODO: Implement analytics
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        //TODO: Implement analytics
    }
}

extension CancelSubscriptionViewModel {
    /// Make the view, and allow it to be shown by itself or within another navigation flow
    static func make() -> UIViewController {
        // If we're not being presented within another nav controller then wrap ourselves in one
        let navController = UINavigationController()
        let viewModel = CancelSubscriptionViewModel(navigationController: navController)

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
