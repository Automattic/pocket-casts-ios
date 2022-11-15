import Foundation
import PocketCastsServer
import SwiftUI

class PlusCoordinator: PlusPricingInfoModel {
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

private extension PlusCoordinator {
    func showModal() {
        guard let navigationController else { return }
        let controller = PlusPurchaseModel.make(in: navigationController)
        controller.presentModally(in: navigationController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: navigationController)
    }
}

extension PlusCoordinator {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let coordinator = PlusCoordinator()
        let view = PlusLandingView(coordinator: coordinator)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? OnboardingNavigationViewController(rootViewController: controller)
        coordinator.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
