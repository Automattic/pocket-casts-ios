import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelConfirmationViewModel: OnboardingModel {
    let navigationController: UINavigationController
    let expirationDate: String?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController

        // Update the expiration date for the view
        let expiriation = SubscriptionHelper.subscriptionRenewalDate()
        self.expirationDate = DateFormatHelper.sharedHelper.longLocalizedFormat(expiriation)
    }

    // MARK: - View actions

    func goBackTapped() {
        Analytics.track(.cancelConfirmationStayButtonTapped)
        navigationController.dismiss(animated: true)
    }

    func cancelTapped() {
        Analytics.track(.cancelConfirmationCancelButtonTapped)

        if FeatureFlag.winback.enabled {
            Task {
                guard let windowScene = await navigationController.view.window?.windowScene else {
                    FileLog.shared.console("[CancelConfirmationViewModel] No window scene available")
                    return
                }
                do {
                    try await IAPHelper.shared.showManageSubscriptions(in: windowScene)

                    await ApiServerHandler.shared.retrieveSubscriptionStatus()

                    await MainActor.run {
                        navigationController.dismiss(animated: true)
                    }
                } catch {
                    FileLog.shared.console("[StoreKit] Error showing manage subscriptions: \(error.localizedDescription)")
                }
            }
        } else {
            let controller = CancelInfoViewController()
            navigationController.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Show / Hide

    func didAppear() {
        Analytics.track(.cancelConfirmationViewShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        Analytics.track(.cancelConfirmationViewDismissed)
    }
}

extension CancelConfirmationViewModel {
    /// Make the view, and allow it to be shown by itself or within another navigation flow
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        // If we're not being presented within another nav controller then wrap ourselves in one
        let navController = navigationController ?? UINavigationController()
        let viewModel = CancelConfirmationViewModel(navigationController: navController)

        // Wrap the SwiftUI view in the hosting view controller
        let swiftUIView = CancelConfirmationView(viewModel: viewModel).setupDefaultEnvironment()

        // Configure the controller
        let controller = OnboardingHostingViewController(rootView: swiftUIView)
        controller.navBarIsHidden = true
        controller.viewModel = viewModel

        // Just return the controller if we're not presenting ourselves
        if navigationController != nil {
            return controller
        }

        // Set the root view of the new nav controller
        navController.setViewControllers([controller], animated: false)

        return navController
    }
}
