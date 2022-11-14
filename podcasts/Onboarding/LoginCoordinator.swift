import Foundation
import SwiftUI

class LoginCoordinator {
    var navigationController: UINavigationController? = nil

    func loginTapped() {
        let controller = SyncSigninViewController()
        navigationController?.pushViewController(controller, animated: true)
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
        let navBarResetter = NavBarStyleResetter()

        let view = LoginLandingView(coordinator: coordinator)
        let controller = LoginLandingHostingController(rootView: view.setupDefaultEnvironment(),
                                                       coordinator: coordinator)

        let navigationController = OnboardingNavigationViewController(rootViewController: controller)
        coordinator.navigationController = navigationController
        navBarResetter.navigationController = navigationController

        return navigationController
    }
}

// MARK: - SyncSigninDelegate

extension LoginCoordinator: SyncSigninDelegate {
    func signingProcessCompleted() {
        print("Handle the next step")
    }
}

// MARK: - ViewEventCoordinator

// Listen for view controller events, so we can override the navbar style
class NavBarStyleResetter: ViewEventCoordinator {
    var navigationController: UINavigationController? = nil

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc func themeDidChange() {
        updateNavigationBarStyle(animated: false)
    }

    func viewDidLoad() {
        updateNavigationBarStyle(animated: false)
    }

    func viewWillAppear(_ animated: Bool) {
        updateNavigationBarStyle(animated: true)
    }

    private func updateNavigationBarStyle(animated: Bool) {
        guard let navController = navigationController else { return }

        let iconColor = AppTheme.colorForStyle(.primaryInteractive01)

        let navigationBar = navController.navigationBar
        navigationBar.backIndicatorImage = UIImage(named: "nav-back")?.tintedImage(iconColor)
        navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav-back")?.tintedImage(iconColor)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.shadowColor = nil

        let applyAppearance = {
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = iconColor
        }

        guard animated else {
            applyAppearance()
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: applyAppearance)
    }
}
