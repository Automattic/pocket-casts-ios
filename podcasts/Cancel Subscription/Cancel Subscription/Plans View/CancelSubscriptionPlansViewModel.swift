import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionPlansViewModel: CancelSubscriptionViewModel {
    private var lastPurchasedProductID: IAPProductID?

    @Published var currentPricingProduct: PlusPricingInfoModel.PlusProductPricingInfo?
    @State var currentProductAvailability: CurrentProductAvailability = .idle

    override class var availableProductIds: [IAPProductID] {
        return [.yearly, .monthly, .patronYearly, .patronMonthly, .yearlyReferral]
    }

    override func handleNext() {
        if let currentPricingProduct {
            Analytics.track(.cancelSubscriptionNewPlanPurchaseSuccessful, properties: ["product": currentPricingProduct.identifier.rawValue])
        } else {
            Analytics.track(.cancelSubscriptionNewPlanPurchaseSuccessful)
        }

        if SubscriptionHelper.activeTier == .patron {
            let controller = PatronWelcomeViewModel.make(in: navigationController)
            navigationController?.pushViewController(controller, animated: true)
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    override func didAppear() {
        Analytics.track(.cancelSubscriptionAvailablePlansShown)
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        Analytics.track(.cancelSubscriptionAvailablePlansDismissed)
        Analytics.track(.cancelSubscriptionDismissed)
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
        Analytics.track(.cancelSubscriptionSelectPlan, properties: ["product": product.identifier.rawValue])

        currentPricingProduct = product

        if currentPricingProduct?.identifier != lastPurchasedProductID {
            purchase(product: product.identifier)
        }
    }

    func closePlans() {
        didDismiss(type: .swipe)

        navigationController?.dismiss(animated: true)
    }

    enum CurrentProductAvailability {
        case idle
        case loading
        case available
        case unavailable
    }
}

extension CancelSubscriptionPlansViewModel {
    static func make(in navigationController: UINavigationController?) -> UIViewController {
        let navController = navigationController ?? UINavigationController()
        let viewModel = CancelSubscriptionPlansViewModel(navigationController: navController)
        viewModel.parentController = navController

        let swiftUIView = CancelSubscriptionPlansView(viewModel: viewModel).setupDefaultEnvironment()

        let controller = OnboardingHostingViewController(rootView: swiftUIView)
        controller.navBarIsHidden = true
        controller.viewModel = viewModel

        return controller
    }
}
