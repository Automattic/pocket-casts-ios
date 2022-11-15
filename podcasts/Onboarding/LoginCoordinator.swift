import Foundation
import SwiftUI

class LoginCoordinator {
    var navigationController: UINavigationController? = nil

    func loginTapped() {

        let controller = PlusCoordinator.make(in: navigationController)
        navigationController?.pushViewController(controller, animated: true)
//        let controller = SyncSigninViewController()
//        navigationController?.pushViewController(controller, animated: true)
    }

    func signUpTapped() {
        let controller = NewEmailViewController(newSubscription: NewSubscription(isNewAccount: true, iap_identifier: ""))
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func dismissTapped() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - Social Buttons
extension LoginCoordinator {
    func signInWithAppleTapped() {

    }

    func signInWithGoogleTapped() {

    }
}

// MARK: - Helpers

extension LoginCoordinator {
    static func make() -> UIViewController {
        let coordinator = LoginCoordinator()
        let view = LoginLandingView(coordinator: coordinator)
        let controller = LoginLandingHostingController(rootView: view.setupDefaultEnvironment(),
                                                       coordinator: coordinator)

        let navigationController = OnboardingNavigationViewController(rootViewController: controller)
        coordinator.navigationController = navigationController

        return navigationController
    }
}

// MARK: - SyncSigninDelegate

extension LoginCoordinator: SyncSigninDelegate {
    func signingProcessCompleted() {
        print("Handle the next step")
    }
}
