import Foundation
import PocketCastsServer
import SwiftUI

class PlusLandingViewModel: PlusPricingInfoModel {
    var navigationController: UINavigationController? = nil
    let isRootView: Bool

    init(isRootView: Bool, purchaseHandler: IapHelper = .shared) {
        self.isRootView = isRootView
        super.init(purchaseHandler: purchaseHandler)
    }

    func unlockTapped() {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal()
            case .failed:
                self.showError()
            default:
                break
            }
        }
    }

    func dismissTapped() {
        navigationController?.dismiss(animated: true)
    }
}

private extension PlusLandingViewModel {
    func showModal() {
        guard let navigationController else { return }
        let controller = PlusPurchaseModel.make(in: navigationController)
        controller.presentModally(in: navigationController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: navigationController)
    }
}

extension PlusLandingViewModel {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let isRootView = navigationController == nil
        let viewModel = PlusLandingViewModel(isRootView: isRootView)
        let view = PlusLandingView(viewModel: viewModel)
        let controller = PlusHostingViewController(rootView: view.setupDefaultEnvironment())
        controller.navBarIsHidden = isRootView

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? OnboardingNavigationViewController(rootViewController: controller)
        viewModel.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
