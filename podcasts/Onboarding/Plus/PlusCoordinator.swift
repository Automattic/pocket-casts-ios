import Foundation
import PocketCastsServer
import SwiftUI

class PlusCoordinator: ObservableObject {
    var navigationController: UINavigationController? = nil

    @Published var isLoadingPrices = false {
        didSet {
            objectWillChange.send()
        }
    }

    func unlockTapped() {
        // If the prices haven't been loaded yet, load them and wait...
        guard IapHelper.shared.hasLoadedProducts else {
            listenForPrices()
            return
        }

        handlePricesLoaded()
    }

    func dismissTapped() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - Price updating
private extension PlusCoordinator {
    private func listenForPrices() {
        isLoadingPrices = true

        NotificationCenter.default.addObserver(self, selector: #selector(handlePricesLoaded), name: ServerNotifications.iapProductsUpdated, object: nil)

        IapHelper.shared.requestProductInfo()
    }

    @objc func handlePricesLoaded() {
        isLoadingPrices = false

        guard let navigationController else { return }

        let controller = PlusPurchaseModel.make(in: navigationController)
        controller.presentModally(in: navigationController)
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
