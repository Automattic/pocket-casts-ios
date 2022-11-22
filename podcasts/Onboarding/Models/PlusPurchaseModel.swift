import UIKit
import SwiftUI
import PocketCastsServer

class PlusPurchaseModel: PlusPricingInfoModel, OnboardingModel {
    var parentController: UIViewController? = nil

    // Keep track of our internal state, and pass this to our view
    @Published var state: PurchaseState = .ready

    private var purchasedProduct: Constants.IapProducts?

    override init(purchaseHandler: IapHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        addPaymentObservers()
    }

    func didAppear() {
        Analytics.track(.selectPaymentFrequencyShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        Analytics.track(.selectPaymentFrequencyDismissed)
    }

    // MARK: - Triggers the purchase process
    func purchase(product: Constants.IapProducts) {
        guard purchaseHandler.buyProduct(identifier: product.rawValue) else {
            handlePurchaseFailed(error: nil)
            return
        }

        Analytics.track(.selectPaymentFrequencyNextButtonTapped, properties: ["product": product.rawValue])

        purchasedProduct = product
        state = .purchasing
    }

    // Our internal state
    enum PurchaseState {
        case ready
        case purchasing
        case deferred
        case successful
        case cancelled
        case failed
    }
}

extension PlusPurchaseModel {
    static func make(in parentController: UIViewController) -> UIViewController {
        let viewModel = PlusPurchaseModel()
        viewModel.parentController = parentController

        let backgroundColor = UIColor(hex: PlusPurchaseModal.Config.backgroundColorHex)
        let modal = PlusPurchaseModal(coordinator: viewModel).setupDefaultEnvironment()
        let controller = OnboardingModalHostingViewController(rootView: modal, backgroundColor: backgroundColor)
        controller.viewModel = viewModel

        return controller
    }
}

private extension PlusPurchaseModel {
    private func addPaymentObservers() {
        let notificationCenter = NotificationCenter.default
        let notifications = [
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
        case ServerNotifications.iapPurchaseCancelled:
            handlePurchaseCancelled(notification)

        case ServerNotifications.iapPurchaseCompleted:
            handlePurchaseCompleted(notification)

        case ServerNotifications.iapPurchaseDeferred:
            handlePurchaseDeferred(notification)

        case ServerNotifications.iapPurchaseFailed:
            handlePurchaseFailed(error: notification.userInfo?["error"] as? NSError)

        default:
            state = .ready
        }
    }
}

private extension PlusPurchaseModel {
    private func handleNext() {
        guard let parentController else { return }

        let viewModel = WelcomeViewModel(displayType: .plus)
        let controller = OnboardingHostingViewController(rootView: WelcomeView(viewModel: viewModel).setupDefaultEnvironment())
        controller.navBarIsHidden = true

        // Create a view controller to present the view in
        guard let navigationController = parentController as? UINavigationController else {
            let navigationController = UINavigationController(rootViewController: controller)
            viewModel.navigationController = navigationController

            parentController.dismiss(animated: true, completion: {
                parentController.present(navigationController, animated: true)
            })
            return
        }

        // Show the welcome view inside the existing nav controller
        viewModel.navigationController = navigationController
        navigationController.dismiss(animated: true, completion: {
            navigationController.setViewControllers([controller], animated: true)
        })
    }
}

// MARK: - Purchase Notification handlers
private extension PlusPurchaseModel {
    func handlePurchaseCompleted(_ notification: Notification) {
        guard let purchasedProduct else {
            state = .failed
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
        state = .deferred
        handleNext()
    }

    func handlePurchaseCancelled(_ notification: Notification) {
        defer { state = .cancelled }
        guard
            let purchasedProduct,
            let error = notification.userInfo?["error"] as? NSError
        else { return }

        purchaseHandler.purchaseWasCancelled(purchasedProduct.rawValue, error: error)
    }

    func handlePurchaseFailed(error: NSError?) {
        defer { state = .failed }

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
