import Foundation
import PocketCastsServer
import SwiftUI

class PlusLandingViewModel: PlusPricingInfoModel {
    var navigationController: UINavigationController? = nil

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
        let viewModel = PlusLandingViewModel()
        let view = PlusLandingView(viewModel: viewModel)
        let controller = PlusHostingViewController(rootView: view.setupDefaultEnvironment())

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? OnboardingNavigationViewController(rootViewController: controller)
        viewModel.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
