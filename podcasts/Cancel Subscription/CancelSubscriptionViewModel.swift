import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionViewModel: PlusPurchaseModel {
    @Published var offerLoadingState: WinbackOfferLoadingState = .idle

    weak var navigationController: UINavigationController?
    var winbackOffer: WinbackOfferInfo?

    var isEligibleForOffer: Bool {
        purchaseHandler.isEligibleForOffer
    }

    init(purchaseHandler: IAPHelper = .shared, navigationController: UINavigationController?) {
        self.navigationController = navigationController

        super.init(purchaseHandler: purchaseHandler)

        self.loadPrices()
    }

    override func didAppear() {
        Analytics.track(.winbackScreenShown, properties: ["screen": "main"])
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        Analytics.track(.winbackScreenDismissed, properties: ["screen": "main"])
    }

    private func trackRow(option: CancelSubscriptionOption) {
        let activeTier = SubscriptionHelper.activeTier
        let frequency = SubscriptionHelper.subscriptionFrequencyValue()
        Analytics.track(.winbackMainScreenRowTap, properties: ["row": option.analyticsRow,
                                                               "tier": activeTier.analyticsDescription,
                                                               "frequency": frequency.analyticsDescription])
    }

    enum WinbackOfferLoadingState {
        case idle, loading, loaded
    }
}

// IAP
extension CancelSubscriptionViewModel {
    func price() -> String? {
        switch (SubscriptionHelper.activeTier, SubscriptionHelper.subscriptionFrequencyValue()) {
        case (.plus, .monthly):
            return pricingInfo.products.first { $0.identifier == .monthly }?.rawPrice
        case (.patron, .monthly):
            return pricingInfo.products.first { $0.identifier == .patronMonthly }?.rawPrice
        case (_, .yearly):
            return winbackOffer?.offerPrice
        default:
            return nil
        }
    }

    func subscriptionFrequency() -> SubscriptionFrequency? {
        switch SubscriptionHelper.subscriptionFrequencyValue() {
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        default:
            return nil
        }
    }

    func loadWinbackOffer() async {
        if offerLoadingState == .loading {
            return
        }
        Task { @MainActor in
            offerLoadingState = .loading
            winbackOffer = await ApiServerHandler.shared.loadWinbackOffer()
            if let iap = winbackOffer?.details?.iap,
               let offerId = winbackOffer?.details?.offerId {
                winbackOffer?.offerPrice = await purchaseHandler.winbackOfferPrice(for: iap, offerId: offerId)
            }
            offerLoadingState = .loaded
        }
    }

    func claimOffer() {
        trackRow(option: .promotion(price: "", frequency: .none))
        //TODO: Apply one month free
        //TODO: Purchase the offer and display the success view if succeeded
        showClaimOfferSuccess()
    }

    func canClaimOffer() -> Bool {
        return winbackOffer != nil
    }
}

// Navigation
extension CancelSubscriptionViewModel {
    func cancelSubscriptionTap() {
        Analytics.track(.winbackContinueButtonTap)

        let viewController = CancelConfirmationViewModel.make(in: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showPlans() {
        trackRow(option: .availablePlans)

        let viewController = CancelSubscriptionPlansViewModel.make(in: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showHelp() {
        trackRow(option: .help)

        let controller = OnlineSupportController(source: .winback)
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(controller, animated: true)
    }

    func showClaimOfferSuccess() {
        Analytics.track(.winbackScreenShown, properties: ["screen": "offer_claimed"])

        let view = CancelSubscriptionOfferSuccessView(viewModel: self).setupDefaultEnvironment()
        let controller = OnboardingHostingViewController(rootView: view)
        controller.navBarIsHidden = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func closeOffer() {
        Analytics.track(.winbackOfferClaimedDoneButtonTapped)

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
