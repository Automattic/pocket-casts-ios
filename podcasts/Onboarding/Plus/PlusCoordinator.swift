import Foundation
import SwiftUI

class PlusCoordinator: ObservableObject {
    var navigationController: UINavigationController? = nil

    func unlockTapped() {
        guard let navigationController else { return }

        let modal = PlusPurchaseModal(coordinator: PlusPurchaseCoordinator())
        MDCSwiftUIWrapper.present(modal, in: navigationController)
    }

    func dismissTapped() {
        navigationController?.dismiss(animated: true)
    }
}

extension PlusCoordinator {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let coordinator = PlusCoordinator()
        let view = PlusLandingView(coordinator: coordinator)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        coordinator.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
