import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionViewModel: PlusPurchaseModel {
    weak var navigationController: UINavigationController?

    var isEligibleForOffer: Bool {
        purchaseHandler.isEligibleForOffer
    }

    init(purchaseHandler: IAPHelper = .shared, navigationController: UINavigationController?) {
        self.navigationController = navigationController

        super.init(purchaseHandler: purchaseHandler)

        self.loadPrices()
    }

    override func didAppear() {
        Analytics.track(.cancelSubscriptionShown)
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        Analytics.track(.cancelSubscriptionDismissed)
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

    func claimOffer() {
        Analytics.track(.cancelSubscriptionRowTap, properties: ["row": "claim_offer"])
        //TODO: Apply one month free
        //TODO: Purchase the offer and display the success view if succeeded
        showClaimOfferSuccess()
    }
}

// Navigation
extension CancelSubscriptionViewModel {
    func cancelSubscriptionTap() {
        Analytics.track(.cancelSubscriptionContinueButtonTap)

        let viewController = CancelConfirmationViewModel.make(in: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showPlans() {
        Analytics.track(.cancelSubscriptionRowTap, properties: ["row": "plans"])
        Analytics.track(.cancelSubscriptionAvailablePlansShown)

        let viewController = CancelSubscriptionPlansViewModel.make(in: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showHelp() {
        Analytics.track(.cancelSubscriptionRowTap, properties: ["row": "help"])

        let controller = OnlineSupportController()
        controller.didDismiss = { [weak self] in
            self?.didDismiss(type: .swipe)
        }
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(controller, animated: true)
    }

    func showClaimOfferSuccess() {
        Analytics.track(.cancelSubscriptionClaimOfferSuccessShown)

        let view = CancelSubscriptionOfferSuccessView(viewModel: self).setupDefaultEnvironment()
        let controller = OnboardingHostingViewController(rootView: view)
        controller.navBarIsHidden = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func closeOffer() {
        didDismiss(type: .swipe)

        navigationController?.dismiss(animated: true)
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
