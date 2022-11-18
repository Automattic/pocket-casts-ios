import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsDataModel

class LoginCoordinator {
    var navigationController: UINavigationController? = nil
    let headerImages: [LoginHeaderImage]
    var presentedFromUpgrade: Bool = false

    init() {
        var randomPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false).map {
            LoginHeaderImage(podcast: $0, imageName: nil)
        }.shuffled()

        let maxCount = bundledImages.count

        if randomPodcasts.count > maxCount {
            randomPodcasts = Array(randomPodcasts[0...maxCount])
        } else if randomPodcasts.count < maxCount {
            randomPodcasts.append(contentsOf: bundledImages[randomPodcasts.count..<maxCount])
        }

        self.headerImages = randomPodcasts
    }

    func loginTapped() {
        let controller = SyncSigninViewController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    func signUpTapped() {
        let controller = NewEmailViewController(newSubscription: NewSubscription(isNewAccount: true, iap_identifier: ""))
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func dismissTapped() {
        navigationController?.dismiss(animated: true)
    }

    private let bundledImages: [LoginHeaderImage] = [
        .init(podcast: nil, imageName: "login-cover-1"),
        .init(podcast: nil, imageName: "login-cover-2"),
        .init(podcast: nil, imageName: "login-cover-3"),
        .init(podcast: nil, imageName: "login-cover-4"),
        .init(podcast: nil, imageName: "login-cover-5"),
        .init(podcast: nil, imageName: "login-cover-6"),
        .init(podcast: nil, imageName: "login-cover-7")
    ]

    struct LoginHeaderImage {
        let podcast: Podcast?
        let imageName: String?
    }
}

// MARK: - Social Buttons
extension LoginCoordinator {
    func signInWithAppleTapped() {

    }

    func signInWithGoogleTapped() {

    }
}

extension LoginCoordinator: SyncSigninDelegate, CreateAccountDelegate {
    func signingProcessCompleted() {
        let shouldDismiss = SubscriptionHelper.hasActiveSubscription() && !presentedFromUpgrade

        if shouldDismiss {
            navigationController?.dismiss(animated: true)
            return
        }

        goToPlus(from: .login)
    }

    func handleAccountCreated() {
        goToPlus(from: .accountCreated)
    }

    private func goToPlus(from source: PlusLandingViewModel.Source) {
        let controller = PlusLandingViewModel.make(in: navigationController, from: source, continueUpgrade: presentedFromUpgrade)
        navigationController?.setViewControllers([controller], animated: true)
    }
}

// MARK: - Helpers

extension LoginCoordinator {
    static func make(in navigationController: UINavigationController? = nil, fromUpgrade: Bool = false) -> UIViewController {
        let coordinator = LoginCoordinator()
        coordinator.presentedFromUpgrade = fromUpgrade

        let view = LoginLandingView(coordinator: coordinator)
        let controller = LoginLandingHostingController(rootView: view.setupDefaultEnvironment(),
                                                       coordinator: coordinator)

        let navController = navigationController ?? OnboardingNavigationViewController(rootViewController: controller)
        navController.isModalInPresentation = true
        coordinator.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
