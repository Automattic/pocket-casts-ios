import SwiftUI
import PocketCastsServer
import PocketCastsUtils

class CancelConfirmationViewModel: OnboardingModel {
    let navigationController: UINavigationController
    let expirationDate: String?
    let subscriptionViewModel: CancelSubscriptionViewModel?

    init(navigationController: UINavigationController, subscriptionViewModel: CancelSubscriptionViewModel? = nil) {
        self.navigationController = navigationController

        // Update the expiration date for the view
        let expiriation = SubscriptionHelper.subscriptionRenewalDate()
        self.expirationDate = DateFormatHelper.sharedHelper.longLocalizedFormat(expiriation)
        self.subscriptionViewModel = subscriptionViewModel
    }

    // MARK: - View actions

    func goBackTapped() {
        if FeatureFlag.winback.enabled {
            Analytics.track(.winbackCancelConfirmationStayButtonTapped)
            // To avoid repeating the event tracking,
            // I forced passing the `swipe` type
            didDismiss(type: .swipe)
        } else {
            Analytics.track(.cancelConfirmationStayButtonTapped)
        }
        navigationController.dismiss(animated: true)
    }

    func cancelTapped() {
        if FeatureFlag.winback.enabled, SubscriptionHelper.subscriptionPlatform() == .iOS {
            Analytics.track(.winbackCancelConfirmationCancelButtonTapped)

            if subscriptionViewModel?.winbackOffer != nil {
                subscriptionViewModel?.showWinbackScreen()
            } else {
                subscriptionViewModel?.showManageSubscriptions()
            }
        } else {
            Analytics.track(.cancelConfirmationCancelButtonTapped)

            let controller = CancelInfoViewController()
            navigationController.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Show / Hide

    func didAppear() {
        if FeatureFlag.winback.enabled {
            Analytics.track(.winbackScreenShown, properties: ["screen": "cancel_confirmation"])
        } else {
            Analytics.track(.cancelConfirmationViewShown)
        }
    }

    func didDismiss(type: OnboardingDismissType) {
        // Since the view can only be dismissed via swipe, only check for that
        guard type == .swipe else { return }

        if FeatureFlag.winback.enabled {
            Analytics.track(.winbackScreenDismissed, properties: ["screen": "cancel_confirmation"])
        } else {
            Analytics.track(.cancelConfirmationViewDismissed)
        }
    }
}

extension CancelConfirmationViewModel {
    /// Make the view, and allow it to be shown by itself or within another navigation flow
    static func make(in navigationController: UINavigationController? = nil, subscriptionViewModel: CancelSubscriptionViewModel? = nil) -> UIViewController {
        // If we're not being presented within another nav controller then wrap ourselves in one
        let navController = navigationController ?? UINavigationController()
        let viewModel = CancelConfirmationViewModel(navigationController: navController, subscriptionViewModel: subscriptionViewModel)

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
