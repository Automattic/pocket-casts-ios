import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionPlansViewModel: CancelSubscriptionViewModel {
    private var lastPurchasedProductID: IAPProductID?

    @Published var currentPricingProduct: PlusPricingInfoModel.PlusProductPricingInfo?
    @Published var currentProductAvailability: CurrentProductAvailability = .idle
    private var previousPricingProductID: String?

    override class var availableProductIds: [IAPProductID] {
        return [.yearly, .monthly, .patronYearly, .patronMonthly, .yearlyReferral]
    }

    override func handleNext() {
        if let currentPricingProduct, let previousPricingProductID {
            Analytics.track(.winbackAvailablePlansNewPlanPurchaseSuccessful, properties: ["current_product": previousPricingProductID, "new_product": currentPricingProduct.identifier.rawValue])
            self.previousPricingProductID = nil
        } else {
            Analytics.track(.winbackAvailablePlansNewPlanPurchaseSuccessful)
        }

        if SubscriptionHelper.activeTier == .patron {
            let controller = PatronWelcomeViewModel.make(in: navigationController)
            navigationController?.pushViewController(controller, animated: true)
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    override func didAppear() {
        Analytics.track(.winbackScreenShown, properties: ["screen": "available_plans"])
    }

    override func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        Analytics.track(.winbackScreenDismissed, properties: ["screen": "available_plans"])
    }

    func getOrderedProducts() -> [PlusPricingInfoModel.PlusProductPricingInfo] {
        let order: [IAPProductID] = [.monthly, .patronMonthly, .yearly, .patronYearly, .yearlyReferral]
        let productMap = Dictionary(uniqueKeysWithValues: pricingInfo.products.map { ($0.identifier, $0) })
        return order.compactMap { productMap[$0] }
    }

    func loadCurrentProduct() async {
        if currentProductAvailability == .loading { return }

        await MainActor.run {
            currentProductAvailability = .loading
        }
        if let transaction = await purchaseHandler.findLastSubscriptionPurchased(),
           let productID = IAPProductID(rawValue: transaction.productID) {
            await MainActor.run {
                lastPurchasedProductID = productID
                currentProductAvailability = .available
                currentPricingProduct = pricingInfo.products.first { $0.identifier == productID }
            }
        } else {
            await MainActor.run {
                currentProductAvailability = .unavailable
            }
            FileLog.shared.console("[CancelSubscriptionViewModel] Could not find last subscription purchased")
        }
    }

    func purchase(product: PlusPricingInfoModel.PlusProductPricingInfo) {
        Analytics.track(.winbackAvailablePlansSelectPlan, properties: ["product": product.identifier.rawValue])

        currentPricingProduct = product

        if currentPricingProduct?.identifier != lastPurchasedProductID {
            previousPricingProductID = lastPurchasedProductID?.rawValue
            purchase(product: product.identifier)
        }
    }

    func closePlans() {
        didDismiss(type: .swipe)

        navigationController?.dismiss(animated: true)
    }

    func popViewController() {
        Analytics.track(.winbackAvailablePlansBackButtonTapped)
        didDismiss(type: .swipe)
        navigationController?.popViewController(animated: true)
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
