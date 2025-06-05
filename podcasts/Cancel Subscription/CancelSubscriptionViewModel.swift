import SwiftUI
import Combine
import PocketCastsServer
import PocketCastsUtils

class CancelSubscriptionViewModel: PlusPurchaseModel {
    @Published var offerLoadingState: WinbackOfferLoadingState = .idle
    @Published var offerPurchasingState: WinbackOfferPurchasingState = .idle

    weak var navigationController: UINavigationController?
    var winbackOffer: WinbackOfferInfo?

    var isEligibleForOffer: Bool {
        purchaseHandler.isEligibleForOffer
    }

    init(purchaseHandler: IAPHelper = .shared, navigationController: UINavigationController?) {
        self.navigationController = navigationController

        super.init(purchaseHandler: purchaseHandler)

        loadPrices()
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

    private var cancellables = Set<AnyCancellable>()
    private func addObservers() {
        // Observe IAP flows notification
        Publishers.Merge4(
            NotificationCenter.default.publisher(for: ServerNotifications.iapProductsFailed),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseFailed),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCancelled),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCompleted)
        )
        .receive(on: OperationQueue.main)
        .sink { [weak self] notification in
            Task {
                await self?.purchaseCompleted(success: notification.name == ServerNotifications.iapPurchaseCompleted)
            }
        }
        .store(in: &cancellables)
    }

    private func removeObservers() {
        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()
    }

    enum WinbackOfferLoadingState {
        case idle, loading, loaded
    }

    enum WinbackOfferPurchasingState {
        case idle, purchasing
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
        if offerPurchasingState == .purchasing {
            return
        }
        if let price = price(), let frequency = subscriptionFrequency() {
            trackRow(option: .promotion(price: price, frequency: frequency))
        }
        purchaseOffer()
    }

    func canClaimOffer() -> Bool {
        return winbackOffer != nil
    }

    private func purchaseOffer() {
        guard let productID = translateToProduct(), let discountInfo = makeDiscountInfo() else {
            return
        }
        offerPurchasingState = .purchasing
        addObservers()
        guard purchaseHandler.buyProduct(identifier: productID, discount: discountInfo) else {
            offerPurchasingState = .idle
            removeObservers()
            return
        }
    }

    private func translateToProduct() -> IAPProductID? {
        guard let iap = winbackOffer?.details?.iap else {
            return nil
        }
        return IAPProductID(rawValue: iap)
    }

    private func makeDiscountInfo() -> IAPDiscountInfo? {
        guard let winbackOffer,
              let details = winbackOffer.details,
              details.type == "offer",
              let offerID = details.offerId,
              let uuidString = details.nonce,
              let uuid = UUID(uuidString: uuidString),
              let timestamp = details.timestampMs,
              let key = details.keyIdentifier,
              let signature = details.signature
        else {
            return nil
        }
        return IAPDiscountInfo(identifier: offerID, uuid: uuid, timestamp: timestamp, key: key, signature: signature)
    }

    private func purchaseCompleted(success: Bool) async {
        if success {
            let redeemSuccess = await redeemCode()
            if redeemSuccess {
                await MainActor.run {
                    offerPurchasingState = .idle
                    removeObservers()
                    showClaimOfferSuccess()
                }
            }
        } else {
            await MainActor.run {
                offerPurchasingState = .idle
                removeObservers()
            }
        }
    }

    private func redeemCode() async -> Bool {
        guard let winbackOffer else {
            return false
        }
        return await ApiServerHandler.shared.redeemCode(winbackOffer.code)
    }
}

// Navigation
extension CancelSubscriptionViewModel {
    func cancelSubscriptionTap() {
        Analytics.track(.winbackContinueButtonTap)

        let viewController = CancelConfirmationViewModel.make(in: navigationController, subscriptionViewModel: self)
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

    func showWinbackScreen() {
        let view = CancelSubscriptionWinbackOfferView(viewModel: self).setupDefaultEnvironment()
        let controller = OnboardingHostingViewController(rootView: view)
        controller.navBarIsHidden = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func showManageSubscriptions() {
        Task { [weak self] in
            guard let self else { return }
            guard let windowScene = await self.navigationController?.view.window?.windowScene else {
                FileLog.shared.console("[CancelConfirmationViewModel] No window scene available")
                return
            }
            do {
                try await IAPHelper.shared.showManageSubscriptions(in: windowScene)

                await ApiServerHandler.shared.retrieveSubscriptionStatus()

                await MainActor.run {
                    if FeatureFlag.winback.enabled {
                        // To avoid repeating the event tracking,
                        // I forced passing the `swipe` type
                        self.didDismiss(type: .swipe)
                    }
                    self.navigationController?.dismiss(animated: true)
                }
            } catch {
                FileLog.shared.console("[StoreKit] Error showing manage subscriptions: \(error.localizedDescription)")
            }
        }
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
