import UIKit
import SwiftUI
import PocketCastsServer

class PlusPurchaseModel: PlusPricingInfoModel, OnboardingModel {
    weak var parentController: UIViewController? = nil

    // Keep track of our internal state, and pass this to our view
    @Published var state: PurchaseState = .ready

    private var purchasedProduct: IAPProductID?

    var plan: Plan = .plus

    override init(purchaseHandler: IAPHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        addPaymentObservers()
    }

    func didAppear() {
        OnboardingFlow.shared.track(.selectPaymentFrequencyShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard state != .purchasing else { return }

        OnboardingFlow.shared.track(.selectPaymentFrequencyDismissed)

        // If the view is presented as its own part
        if parentController as? UINavigationController == nil {
            OnboardingFlow.shared.reset()
        }
    }

    func reset() {
        state = .ready
    }

    // MARK: - Triggers the purchase process
    func purchase(product: IAPProductID) {
        guard purchaseHandler.canMakePurchases else {
            showPurchaseDisabledAlert(product: product)
            return
        }

        guard purchaseHandler.buyProduct(identifier: product) else {
            handlePurchaseFailed(error: nil)
            return
        }

        OnboardingFlow.shared.track(.selectPaymentFrequencyNextButtonTapped, properties: ["product": product.rawValue])

        purchasedProduct = product
        state = .purchasing
    }

    func showPurchaseDisabledAlert(product: IAPProductID) {
        guard let presentingViewController = parentController ?? SceneHelper.rootViewController() else {
            return
        }

        let displayName = product.subscriptionTier.displayName

        let alert = UIAlertController(title: L10n.betaThankYou,
                                      message: L10n.betaPurchaseDisabled(displayName),
                                      preferredStyle: .alert)

        alert.addAction(.init(title: L10n.ok, style: .cancel))

        let controller = (presentingViewController.presentedViewController ?? presentingViewController)
        controller.present(alert, animated: true)
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
    static func make(in parentController: UIViewController?, plan: Plan, selectedPrice: PlanFrequency) -> UIViewController {
        let viewModel = PlusPurchaseModel()
        viewModel.parentController = parentController
        viewModel.plan = plan

        let backgroundColor = ThemeColor.primaryUi01()
        let modal = PlusPurchaseModal(coordinator: viewModel, selectedPrice: selectedPrice).setupDefaultEnvironment()
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

        if OnboardingFlow.shared.currentFlow.shouldDismissAfterPurchase {
            parentController.dismiss(animated: true)
            return
        }

        let navigationController = parentController as? UINavigationController

        let controller: UIViewController
        if SubscriptionHelper.activeTier == .patron {
            controller = PatronWelcomeViewModel.make(in: navigationController)
        } else {
            controller = WelcomeViewModel.make(in: navigationController, displayType: .plus)
        }

        let presentNextBlock: () -> Void = {
            guard let navigationController else {
                // Present the welcome flow
                parentController.present(controller, animated: true)
                return
            }

            // Reset the nav flow to only show the welcome controller
            navigationController.setViewControllers([controller], animated: true)
        }

        // Dismiss the current flow
        presentNextBlock()
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
        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
        SubscriptionHelper.subscriptionTier = purchasedProduct.subscriptionTier

        let currentDate = Date()
        var dateComponent = DateComponents()

        let frequency: SubscriptionFrequency
        switch purchasedProduct {

        case .yearly, .patronYearly:
            frequency = .yearly
            dateComponent.year = 1

        case .monthly, .patronMonthly:
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

        purchaseHandler.purchaseWasSuccessful(purchasedProduct)

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

        purchaseHandler.purchaseWasCancelled(purchasedProduct, error: error)
    }

    func handlePurchaseFailed(error: NSError?) {
        defer { state = .failed }

        guard let purchasedProduct else { return }
        purchaseHandler.purchaseFailed(purchasedProduct, error: error ?? defaultError)
    }

    private var defaultError: NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: "Failed to initiate purchase.",
            NSLocalizedFailureReasonErrorKey: "Failed because the product isn't available, or the user isn't signed in"
        ]

        return NSError(domain: "com.pocketcasts.iap", code: 1, userInfo: userInfo)
    }
}
