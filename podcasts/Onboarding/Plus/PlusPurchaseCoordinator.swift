import UIKit
import SwiftUI
import PocketCastsServer

class PlusPurchaseCoordinator: ObservableObject {
    var navigationController: UINavigationController? = nil

    // Allow injection of the IapHelper
    let purchaseHandler: IapHelper

    // Keep track of our internal state, and pass this to our view
    @Published var state: PurchaseState = .ready

    // Allow our views to get the necessary pricing information
    @Published var pricingInfo: PlusPricingInfo

    private var purchasedProduct: Constants.IapProducts?

    init(purchaseHandler: IapHelper = .shared) {
        self.purchaseHandler = purchaseHandler
        self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)

        // If we don't have all the prices, then put us in the waiting state
        if self.pricingInfo.products.filter({ $0.price == nil }).count > 0 {
            self.state = .waitingForPrices
        }

        addPaymentObservers()
    }

    // MARK: - Triggers the purchase process
    func purchase(product: Constants.IapProducts) {
        guard purchaseHandler.buyProduct(identifier: product.rawValue) else {
            handlePurchaseFailed(error: nil)
            return
        }

        self.purchasedProduct = product
        updateState(.purchasing)
    }

    // Our internal state
    enum PurchaseState {
        case ready
        case waitingForPrices
        case purchasing
        case deferred
        case successful
        case cancelled
        case failed
    }

    // A simple struct to keep track of the product and pricing information the view needs
    struct PlusPricingInfo {
        let products: [PlusProductPricingInfo]
        let firstFreeTrial: IapHelper.FreeTrialDetails?
        var hasFreeTrial: Bool { firstFreeTrial != nil }
    }

    struct PlusProductPricingInfo: Identifiable {
        let identifier: Constants.IapProducts
        let price: String?
        let freeTrialDuration: String?

        var id: String { identifier.rawValue }
    }
}

extension PlusPurchaseCoordinator {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let coordinator = PlusPurchaseCoordinator()
        coordinator.navigationController = navigationController

        let backgroundColor = UIColor(hex: PlusPurchaseModal.Config.backgroundColorHex)
        let modal = PlusPurchaseModal(coordinator: coordinator)
        let controller = MDCSwiftUIWrapper(rootView: modal, backgroundColor: backgroundColor)

        return controller
    }
}

private extension PlusPurchaseCoordinator {
    private func addPaymentObservers() {
        let notificationCenter = NotificationCenter.default
        let notifications = [
            ServerNotifications.iapProductsUpdated,
            ServerNotifications.iapPurchaseCompleted,
            ServerNotifications.iapPurchaseDeferred,
            ServerNotifications.iapPurchaseFailed,
            ServerNotifications.iapPurchaseCancelled
        ]

        let selector = #selector(handlePaymentNotification(notification:))

        for notification in notifications {
            notificationCenter.addObserver(self, selector: selector, name: notification, object: nil)
        }
    }

    // MARK: - Private
    @objc func handlePaymentNotification(notification: Notification) {
        switch notification.name {
        case ServerNotifications.iapProductsUpdated:
            handleProductsUpdated()
        case ServerNotifications.iapPurchaseCancelled:
            handlePurchaseCancelled(notification)

        case ServerNotifications.iapPurchaseCompleted:
            handlePurchaseCompleted(notification)

        case ServerNotifications.iapPurchaseDeferred:
            handlePurchaseDeferred(notification)

        case ServerNotifications.iapPurchaseFailed:
            handlePurchaseFailed(error: notification.userInfo?["error"] as? NSError)

        default:
            updateState(.ready)
        }
    }

    private static func getPricingInfo(from purchaseHandler: IapHelper) -> PlusPricingInfo {
        let products: [Constants.IapProducts] = [.yearly, .monthly]
        var pricing: [PlusProductPricingInfo] = []

        for product in products {
            let price = purchaseHandler.getPriceWithFrequency(for: product)
            let trial = purchaseHandler.localizedFreeTrialDuration(product)

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              freeTrialDuration: trial)
            pricing.append(info)
        }

        return PlusPricingInfo(products: pricing, firstFreeTrial: purchaseHandler.getFirstFreeTrialDetails())
    }

    private func updateState(_ state: PurchaseState) {
        self.state = state
        self.objectWillChange.send()
    }
}

private extension PlusPurchaseCoordinator {
    private func handleNext() {
        // Temporary: Push to the account updated controller
        let upgradedVC = AccountUpdatedViewController()
        upgradedVC.titleText = L10n.accountUpgraded
        upgradedVC.detailText = L10n.accountWelcomePlus
        upgradedVC.imageName = AppTheme.plusCreatedImageName
        upgradedVC.hideNewsletter = false

        // Hide the modal, then push
        navigationController?.dismiss(animated: true, completion: {
            self.navigationController?.pushViewController(upgradedVC, animated: true)
        })
    }
}

// MARK: - Purchase Notification handlers
private extension PlusPurchaseCoordinator {
    func handleProductsUpdated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.pricingInfo = Self.getPricingInfo(from: self.purchaseHandler)
            self.updateState(.ready)
            self.objectWillChange.send()
        }
    }

    func handlePurchaseCompleted(_ notification: Notification) {
        guard let purchasedProduct else {
            updateState(.failed)
            return
        }

        SubscriptionHelper.setSubscriptionPaid(1)
        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.iOS.rawValue)
        SubscriptionHelper.setSubscriptionAutoRenewing(true)

        let currentDate = Date()
        var dateComponent = DateComponents()

        let frequency: SubscriptionFrequency
        switch purchasedProduct {

        case .yearly:
            frequency = .yearly
            dateComponent.year = 1

        case .monthly:
            dateComponent.month = 1
            frequency = .monthly
        }

        SubscriptionHelper.setSubscriptionFrequency(frequency.rawValue)

        if let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate) {
            SubscriptionHelper.setSubscriptionExpiryDate(futureDate.timeIntervalSince1970)
        }

        NotificationCenter.default.post(name: ServerNotifications.subscriptionStatusChanged, object: nil)
        Settings.setLoginDetailsUpdated()
        AnalyticsHelper.plusPlanPurchased()

        purchaseHandler.purchaseWasSuccessful(purchasedProduct.rawValue)

        handleNext()
    }

    func handlePurchaseDeferred(_ notification: Notification) {
        updateState(.deferred)
        handleNext()
    }

    func handlePurchaseCancelled(_ notification: Notification) {
        defer { updateState(.cancelled) }
        guard
            let purchasedProduct,
            let error = notification.userInfo?["error"] as? NSError
        else { return }

        purchaseHandler.purchaseWasCancelled(purchasedProduct.rawValue, error: error)
    }

    func handlePurchaseFailed(error: NSError?) {
        defer { updateState(.failed) }

        guard let purchasedProduct else { return }
        purchaseHandler.purchaseFailed(purchasedProduct.rawValue, error: error ?? defaultError)
    }

    private var defaultError: NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: "Failed to initiate purchase.",
            NSLocalizedFailureReasonErrorKey: "Failed because the product isn't available, or the user isn't signed in"
        ]

        return NSError(domain: "com.pocketcasts.iap", code: 1, userInfo: userInfo)
    }
}
