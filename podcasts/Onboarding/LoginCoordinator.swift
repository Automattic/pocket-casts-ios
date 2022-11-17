import Foundation
import SwiftUI
import PocketCastsDataModel

class LoginCoordinator {
    var navigationController: UINavigationController? = nil

    let headerImages: [LoginHeaderImage]

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
        let controller = PlusLandingViewModel.make(in: navigationController)
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
